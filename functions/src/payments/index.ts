import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import { ethers } from "ethers";
import { defineSecret } from "firebase-functions/params";

const bscRpcUrl = defineSecret("BSC_RPC_URL");

export const createPremiumQuote = onCall({ maxInstances: 20 }, async (req) => {
  if (!req.auth) throw new HttpsError("unauthenticated", "Authentication required.");
  const planId = req.data?.planId;
  if (typeof planId !== "string" || !planId.startsWith("premium_")) {
    throw new HttpsError("invalid-argument", "A valid Premium plan is required.");
  }
  const db = getFirestore();
  const planDoc = await db.collection("plans").doc(planId).get();
  if (!planDoc.exists) throw new HttpsError("not-found", "Premium plan not found.");
  const plan = planDoc.data()!;
  if (plan.isActive !== true || plan.tokenSymbol !== "E-FORCE" ||
      !Number.isInteger(plan.chainId) || !ethers.isAddress(plan.token) ||
      Number(plan.chainId) !== 97 || !Number.isInteger(plan.tokenDecimals) ||
      plan.tokenDecimals < 0 || plan.tokenDecimals > 36 ||
      !ethers.isAddress(plan.receiver) || typeof plan.price !== "string" ||
      !/^\d+$/.test(plan.price) || BigInt(plan.price) <= 0n ||
      !Number.isInteger(plan.durationDays) || plan.durationDays <= 0) {
    throw new HttpsError("failed-precondition", "This E-FORCE plan is not configured.");
  }
  const now = new Date();
  const expiresAt = new Date(now.getTime() + 30 * 60 * 1000);
  const quoteRef = db.collection("paymentQuotes").doc();
  await quoteRef.set({
    userId: req.auth.uid, planId, amount: plan.price,
    chainId: plan.chainId, token: ethers.getAddress(plan.token),
    receiver: ethers.getAddress(plan.receiver), tokenSymbol: "E-FORCE",
    tokenDecimals: plan.tokenDecimals,
    createdAt: Timestamp.fromDate(now), expiresAt: Timestamp.fromDate(expiresAt),
    status: "open",
  });
  return {
    quoteId: quoteRef.id, planId, amount: plan.price,
    chainId: plan.chainId, token: ethers.getAddress(plan.token),
    tokenDecimals: plan.tokenDecimals,
    receiver: ethers.getAddress(plan.receiver), tokenSymbol: "E-FORCE",
    durationDays: plan.durationDays, expiresAt: expiresAt.toISOString(),
    usdListPriceCents: plan.usdListPriceCents ?? null,
  };
});

export const verifyPayment = onCall(
  {
    maxInstances: 10,
    secrets: [bscRpcUrl],
  },
  async (req) => {
    if (!req.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }

    const { quoteId, txHash } = req.data;
    if (typeof quoteId !== "string" || !quoteId || !txHash) {
      throw new HttpsError("invalid-argument", "quoteId and txHash are required.");
    }

    const db = getFirestore();
    const callerId = req.auth.uid;

    if (typeof txHash !== "string" || !/^0x[0-9a-fA-F]{64}$/.test(txHash)) {
      throw new HttpsError("invalid-argument", "Invalid transaction hash.");
    }
    const rpcUrl = bscRpcUrl.value();
    if (!rpcUrl) {
      throw new HttpsError("failed-precondition", "Payment verification is not configured.");
    }

    const quoteRef = db.collection("paymentQuotes").doc(quoteId);
    const quoteDoc = await quoteRef.get();
    if (!quoteDoc.exists || quoteDoc.data()?.userId !== callerId) {
      throw new HttpsError("failed-precondition", "Price quote is invalid.");
    }
    const quote = quoteDoc.data()!;
    const paymentRef = db.collection("payments").doc(`${quote.chainId}_${txHash.toLowerCase()}`);
    const priorPayment = await paymentRef.get();
    if (priorPayment.exists) {
      const existing = priorPayment.data()!;
      if (existing.userId !== callerId || existing.quoteId !== quoteId) {
        throw new HttpsError("already-exists", "This transaction has already been claimed.");
      }
      const existingSubscription = await db.collection("subscriptions").doc(callerId).get();
      return {
        success: existing.status === "confirmed", status: existing.status,
        paymentId: paymentRef.id,
        expiresAt: existingSubscription.data()?.expiresAt?.toDate().toISOString() ?? null,
      };
    }
    if (quote.status !== "open") {
      throw new HttpsError("failed-precondition", "Price quote has already been used.");
    }
    const planId = quote.planId as string;
    const planDoc = await db.collection("plans").doc(planId).get();
    if (!planDoc.exists) throw new HttpsError("not-found", "Plan not found.");
    const plan = planDoc.data()!;
    if (plan.isActive !== true || plan.tokenSymbol !== "E-FORCE" ||
        Number(plan.chainId) !== Number(quote.chainId) ||
        Number(plan.tokenDecimals) !== Number(quote.tokenDecimals) ||
        ethers.getAddress(plan.token) !== ethers.getAddress(quote.token) ||
        ethers.getAddress(plan.receiver) !== ethers.getAddress(quote.receiver) ||
        typeof quote.amount !== "string" || !/^\d+$/.test(quote.amount) ||
        !Number.isInteger(plan.durationDays) || plan.durationDays <= 0) {
      throw new HttpsError("failed-precondition", "Quoted E-FORCE plan configuration is invalid.");
    }

    // 3. Verify on BNB Smart Chain via provider
    let fromAddress: string;
    let toAddress: string;
    let tokenAmount: string;
    let receiptBlock: number;
    let receiptTimestamp: number;
    try {
      const provider = new ethers.JsonRpcProvider(rpcUrl);
      const network = await provider.getNetwork();
      if (Number(network.chainId) !== Number(quote.chainId)) {
        throw new HttpsError("failed-precondition", "Payment verifier is connected to the wrong chain.");
      }
      const txReceipt = await provider.getTransactionReceipt(txHash);

      if (!txReceipt || txReceipt.status !== 1) {
        throw new HttpsError("failed-precondition", "Transaction has not succeeded on chain.");
      }

      const tx = await provider.getTransaction(txHash);
      if (!tx) throw new HttpsError("not-found", "Transaction not found.");
      const includedBlock = await provider.getBlock(txReceipt.blockNumber);
      if (!includedBlock) throw new HttpsError("unavailable", "Transaction block is not available.");
      receiptTimestamp = includedBlock.timestamp;
      const quoteStart = quote.createdAt.toDate().getTime() - 60_000;
      const quoteEnd = quote.expiresAt.toDate().getTime() + 60_000;
      const paidAt = receiptTimestamp * 1000;
      if (paidAt < quoteStart || paidAt > quoteEnd) {
        throw new HttpsError("failed-precondition", "Payment was made outside the locked price window.");
      }
      const transferTopic = ethers.id("Transfer(address,address,uint256)");
      const expectedToken = ethers.getAddress(plan.token);
      const expectedReceiverTopic = ethers.zeroPadValue(ethers.getAddress(plan.receiver), 32).toLowerCase();
      const transfer = txReceipt.logs.find((log) =>
        log.address.toLowerCase() === expectedToken.toLowerCase() &&
        log.topics[0] === transferTopic && log.topics.length === 3 &&
        log.topics[1].toLowerCase() === ethers.zeroPadValue(tx.from, 32).toLowerCase() &&
        log.topics[2].toLowerCase() === expectedReceiverTopic);
      if (!transfer) throw new HttpsError("failed-precondition", "Expected token transfer not found.");
      const decoded = ethers.AbiCoder.defaultAbiCoder().decode(["uint256"], transfer.data);
      tokenAmount = decoded[0].toString();
      if (BigInt(tokenAmount) < BigInt(quote.amount)) {
        throw new HttpsError("failed-precondition", "Payment amount is below the plan price.");
      }
      fromAddress = ethers.getAddress(tx.from);
      toAddress = ethers.getAddress(plan.receiver);
      receiptBlock = txReceipt.blockNumber;

      const wallet = await db.collection("wallets").doc(`eip155_${fromAddress.toLowerCase()}`).get();
      if (!wallet.exists || wallet.data()?.userId !== callerId) {
        throw new HttpsError("permission-denied", "Payment sender is not linked to this account.");
      }
    } catch (err: any) {
      if (err instanceof HttpsError) throw err;
      throw new HttpsError("unavailable", "Could not verify the transaction on BSC.");
    }

    const provider = new ethers.JsonRpcProvider(rpcUrl);
    const head = await provider.getBlockNumber();
    const confirmations = head - receiptBlock + 1;
    const confirmed = confirmations >= 12;
    const grantRef = db.collection("premiumGrants").doc(`token_${quote.chainId}_${txHash.toLowerCase()}`);
    const subRef = db.collection("subscriptions").doc(callerId);
    const profileRef = db.collection("users").doc(callerId);
    const now = new Date();
    let expiresAt: Date | undefined;
    let responseStatus: "pending" | "confirmed" = confirmed ? "confirmed" : "pending";

    await db.runTransaction(async (t) => {
      const payment = await t.get(paymentRef);
      if (payment.exists) {
        const existing = payment.data()!;
        if (existing.userId !== callerId || existing.planId !== planId) {
          throw new HttpsError("already-exists", "This transaction has already been claimed.");
        }
        responseStatus = existing.status === "confirmed" ? "confirmed" : "pending";
        if (responseStatus === "confirmed") {
          const sub = await t.get(subRef);
          expiresAt = sub.data()?.expiresAt?.toDate();
        }
        return;
      }
      const [sub, profile, freshQuote, grant] = await Promise.all([
        t.get(subRef), t.get(profileRef), t.get(quoteRef), t.get(grantRef),
      ]);
      if (!freshQuote.exists || freshQuote.data()?.status !== "open" ||
          freshQuote.data()?.userId !== callerId) {
        throw new HttpsError("failed-precondition", "Price quote expired or already used.");
      }
      if (grant.exists) throw new HttpsError("already-exists", "This payment has already granted Premium.");
      const currentPremiumUntil = profile.data()?.premiumUntil?.toDate() as Date | undefined;
      const previousExpiry = currentPremiumUntil;
      const startsAt = previousExpiry && previousExpiry > now ? previousExpiry : now;
      expiresAt = confirmed
        ? new Date(startsAt.getTime() + plan.durationDays * 24 * 60 * 60 * 1000)
        : undefined;
      t.set(paymentRef, {
        id: paymentRef.id,
        userId: callerId,
        planId,
        chainNamespace: "eip155",
        chainId: quote.chainId,
        txHash: txHash.toLowerCase(),
        fromAddress,
        toAddress,
        token: ethers.getAddress(plan.token),
        amount: tokenAmount,
        requiredAmount: quote.amount,
        tokenDecimals: plan.tokenDecimals,
        quoteId,
        tokenSymbol: "E-FORCE",
        status: confirmed ? "confirmed" : "pending",
        confirmations,
        blockNumber: receiptBlock,
        verifiedAt: confirmed ? FieldValue.serverTimestamp() : null,
        createdAt: FieldValue.serverTimestamp(),
      });
      t.update(quoteRef, { status: "used", paymentId: paymentRef.id, usedAt: FieldValue.serverTimestamp() });
      if (confirmed && expiresAt) {
        t.set(grantRef, {
          userId: callerId, source: "token", externalRef: `${quote.chainId}:${txHash.toLowerCase()}`,
          planId, days: plan.durationDays, status: "active", paymentId: paymentRef.id,
          createdAt: FieldValue.serverTimestamp(),
        });
        t.set(profileRef, { premiumUntil: Timestamp.fromDate(expiresAt) }, { merge: true });
        t.set(subRef, {
          userId: callerId, planId, planSlug: plan.slug,
          paymentId: paymentRef.id, status: "active",
          startsAt: Timestamp.fromDate(previousExpiry && previousExpiry > now ? previousExpiry : now),
          expiresAt: Timestamp.fromDate(expiresAt), createdAt: FieldValue.serverTimestamp(),
        });
      }
    });

    return {
      success: responseStatus === "confirmed",
      status: responseStatus,
      paymentId: paymentRef.id,
      expiresAt: expiresAt?.toISOString() ?? null,
    };
  }
);

// Scheduled job expiring outdated subscriptions
export const expireSubscriptions = onSchedule("every 24 hours", async () => {
  const db = getFirestore();
  const now = Timestamp.now();
  const expiredDocs = await db
    .collection("subscriptions")
    .where("status", "==", "active")
    .where("expiresAt", "<", now)
    .get();

  const batch = db.batch();
  for (const doc of expiredDocs.docs) {
    batch.update(doc.ref, { status: "expired" });
  }
  await batch.commit();
});

export const recheckPayments = onSchedule({ schedule: "every 5 minutes", secrets: [bscRpcUrl] }, async () => {
  const rpcUrl = bscRpcUrl.value();
  if (!rpcUrl) return;
  const db = getFirestore();
  const provider = new ethers.JsonRpcProvider(rpcUrl);
  const network = await provider.getNetwork();
  if (Number(network.chainId) !== 97) return;
  const pending = await db.collection("payments").where("status", "==", "pending").limit(100).get();

  for (const doc of pending.docs) {
    try {
      const payment = doc.data();
      const [receipt, tx, planDoc] = await Promise.all([
        provider.getTransactionReceipt(payment.txHash),
        provider.getTransaction(payment.txHash),
        db.collection("plans").doc(payment.planId).get(),
      ]);
      if (!receipt || receipt.status !== 1 || !tx) {
        if (payment.createdAt?.toDate && Date.now() - payment.createdAt.toDate().getTime() > 24 * 60 * 60 * 1000) {
          await doc.ref.update({ status: "rejected", rejectedAt: FieldValue.serverTimestamp() });
        }
        continue;
      }
      if (!planDoc.exists) continue;
      const plan = planDoc.data()!;
      if (plan.isActive !== true || plan.tokenSymbol !== "E-FORCE" || Number(plan.chainId) !== Number(payment.chainId) ||
          Number(plan.tokenDecimals) !== Number(payment.tokenDecimals) ||
          !ethers.isAddress(plan.token) || !ethers.isAddress(plan.receiver) ||
          typeof payment.requiredAmount !== "string" || !/^\d+$/.test(payment.requiredAmount) ||
          !Number.isInteger(plan.durationDays) || plan.durationDays <= 0) continue;
      const transferTopic = ethers.id("Transfer(address,address,uint256)");
      const fromTopic = ethers.zeroPadValue(tx.from, 32).toLowerCase();
      const receiverTopic = ethers.zeroPadValue(ethers.getAddress(plan.receiver), 32).toLowerCase();
      const log = receipt.logs.find((entry) => entry.address.toLowerCase() === plan.token.toLowerCase() &&
        entry.topics[0] === transferTopic && entry.topics.length === 3 &&
        entry.topics[1].toLowerCase() === fromTopic && entry.topics[2].toLowerCase() === receiverTopic);
      if (!log || BigInt(ethers.AbiCoder.defaultAbiCoder().decode(["uint256"], log.data)[0]) < BigInt(payment.requiredAmount)) {
        await doc.ref.update({ status: "rejected", rejectedAt: FieldValue.serverTimestamp() });
        continue;
      }
      const wallet = await db.collection("wallets").doc(`eip155_${tx.from.toLowerCase()}`).get();
      if (!wallet.exists || wallet.data()?.userId !== payment.userId) {
        await doc.ref.update({ status: "rejected", rejectedAt: FieldValue.serverTimestamp() });
        continue;
      }
      const confirmations = await provider.getBlockNumber() - receipt.blockNumber + 1;
      if (confirmations < 12) {
        await doc.ref.update({ confirmations });
        continue;
      }

      const subRef = db.collection("subscriptions").doc(payment.userId);
      const profileRef = db.collection("users").doc(payment.userId);
      const grantRef = db.collection("premiumGrants").doc(`token_${payment.chainId}_${payment.txHash}`);
      await db.runTransaction(async (t) => {
        const [freshPayment, sub, profile, grant] = await Promise.all([
          t.get(doc.ref), t.get(subRef), t.get(profileRef), t.get(grantRef),
        ]);
        if (!freshPayment.exists || freshPayment.data()?.status !== "pending") return;
        if (grant.exists) {
          t.update(doc.ref, { status: "rejected", rejectedAt: FieldValue.serverTimestamp() });
          return;
        }
        const now = new Date();
        const oldExpiry = profile.data()?.premiumUntil?.toDate() as Date | undefined;
        const startsAt = oldExpiry && oldExpiry > now ? oldExpiry : now;
        const expiresAt = new Date(startsAt.getTime() + plan.durationDays * 24 * 60 * 60 * 1000);
        t.update(doc.ref, { status: "confirmed", confirmations, verifiedAt: FieldValue.serverTimestamp() });
        t.set(grantRef, {
          userId: payment.userId, source: "token",
          externalRef: `${payment.chainId}:${payment.txHash}`,
          planId: payment.planId, days: plan.durationDays, status: "active",
          paymentId: doc.id, createdAt: FieldValue.serverTimestamp(),
        });
        t.set(profileRef, { premiumUntil: Timestamp.fromDate(expiresAt) }, { merge: true });
        t.set(subRef, {
          userId: payment.userId, planId: payment.planId, planSlug: plan.slug,
          paymentId: doc.id, status: "active", startsAt: Timestamp.fromDate(startsAt),
          expiresAt: Timestamp.fromDate(expiresAt), updatedAt: FieldValue.serverTimestamp(),
        });
      });
    } catch (error) {
      console.error("Pending payment recheck failed", doc.id, error);
    }
  }
});
