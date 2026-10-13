import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";
import { ethers } from "ethers";
import * as crypto from "crypto";

const DOMAIN = "elitechat.app";
const ALLOWED_CHAINS = [56, 97]; // BNB Smart Chain mainnet and testnet

export const authNonce = onCall(
  {
    enforceAppCheck: false,
    maxInstances: 20,
  },
  async (req) => {
    const { address, chainId = 97 } = req.data;
    if (!address || typeof address !== "string" || !ethers.isAddress(address)) {
      throw new HttpsError("invalid-argument", "Valid wallet address required.");
    }

    if (!ALLOWED_CHAINS.includes(Number(chainId))) {
      throw new HttpsError("invalid-argument", "Unsupported chain ID.");
    }

    const db = getFirestore();
    const nonce = crypto.randomBytes(16).toString("hex");
    const normalizedAddress = ethers.getAddress(address);
    const now = new Date();
    const expiresAt = new Date(now.getTime() + 5 * 60 * 1000); // 5 min expiry

    const message = `${DOMAIN} wants you to sign in with your Ethereum account:\n${normalizedAddress}\n\nSign in to EliteChat. This does not send a transaction or cost any gas.\n\nURI: https://${DOMAIN}\nVersion: 1\nChain ID: ${chainId}\nNonce: ${nonce}\nIssued At: ${now.toISOString()}\nExpiration Time: ${expiresAt.toISOString()}`;

    await db.collection("authNonces").doc(nonce).set({
      nonce,
      address: normalizedAddress,
      chainId,
      domain: DOMAIN,
      uri: `https://${DOMAIN}`,
      issuedAt: Timestamp.fromDate(now),
      expiresAt: Timestamp.fromDate(expiresAt),
      used: false,
    });

    return { message, nonce };
  }
);

export const authVerify = onCall(
  {
    enforceAppCheck: false,
    maxInstances: 20,
  },
  async (req) => {
    const { message, signature } = req.data;
    if (typeof message !== "string" || typeof signature !== "string" ||
        message.length > 2048 || !/^0x[0-9a-fA-F]{130}$/.test(signature)) {
      throw new HttpsError("invalid-argument", "Message and signature required.");
    }

    // 1. Parse SIWE message fields
    const parsed = message.match(/^([^\s]+) wants you to sign in with your Ethereum account:\n(0x[a-fA-F0-9]{40})\n\nSign in to EliteChat\. This does not send a transaction or cost any gas\.\n\nURI: (https:\/\/[^\s]+)\nVersion: 1\nChain ID: (\d+)\nNonce: ([a-fA-F0-9]{32})\nIssued At: ([^\n]+)\nExpiration Time: ([^\n]+)$/);
    if (!parsed || parsed[1] !== DOMAIN || parsed[3] !== `https://${DOMAIN}`) {
      throw new HttpsError("invalid-argument", "Malformed sign-in message.");
    }

    const claimedAddress = ethers.getAddress(parsed[2]);
    const chainId = Number(parsed[4]);
    const nonce = parsed[5];
    const issuedAt = Date.parse(parsed[6]);
    const expirationTime = Date.parse(parsed[7]);
    const nowMs = Date.now();
    if (!ALLOWED_CHAINS.includes(chainId) || !Number.isFinite(issuedAt) ||
        !Number.isFinite(expirationTime) || issuedAt > nowMs + 60_000 ||
        expirationTime <= nowMs || expirationTime - issuedAt > 5 * 60_000 ||
        issuedAt > expirationTime) {
      throw new HttpsError("failed-precondition", "Invalid or expired sign-in request.");
    }

    const db = getFirestore();
    const auth = getAuth();

    // 2. Atomically consume the nonce in a Firestore transaction
    const nonceRef = db.collection("authNonces").doc(nonce);
    await db.runTransaction(async (t) => {
      const doc = await t.get(nonceRef);
      if (!doc.exists) {
        throw new HttpsError("not-found", "Invalid or expired sign-in nonce.");
      }
      const data = doc.data()!;
      if (data.used || data.expiresAt.toDate() <= new Date() ||
          data.address !== claimedAddress || data.chainId !== chainId ||
          data.issuedAt.toMillis() !== issuedAt) {
        throw new HttpsError("failed-precondition", "Nonce has expired or was already used.");
      }
      t.update(nonceRef, { used: true, usedAt: FieldValue.serverTimestamp() });
    });

    // 3. Cryptographically recover signer
    let recoveredAddress: string;
    try {
      recoveredAddress = ethers.verifyMessage(message, signature);
    } catch {
      throw new HttpsError("unauthenticated", "Invalid cryptographic signature.");
    }

    if (ethers.getAddress(recoveredAddress) !== claimedAddress) {
      throw new HttpsError("unauthenticated", "Signature does not match claiming address.");
    }

    // 4. Find or create user
    const walletRef = db.collection("wallets").doc(`eip155_${claimedAddress.toLowerCase()}`);
    const walletDoc = await walletRef.get();

    let uid: string;
    if (walletDoc.exists) {
      uid = walletDoc.data()!.userId;
    } else {
      uid = `web3_${claimedAddress.toLowerCase()}`;
      try {
        await auth.getUser(uid);
      } catch {
        await auth.createUser({
          uid,
          displayName: `0x${claimedAddress.slice(2, 6)}...${claimedAddress.slice(-4)}`,
        });
      }

      await db.runTransaction(async (t) => {
        t.set(walletRef, {
          userId: uid,
          chainNamespace: "eip155",
          address: claimedAddress,
          isPrimary: true,
          linkedAt: FieldValue.serverTimestamp(),
        });

        const userRef = db.collection("users").doc(uid);
        t.set(userRef, {
          id: uid,
          handle: `user_${claimedAddress.slice(2, 8).toLowerCase()}`,
          displayName: `0x${claimedAddress.slice(2, 6)}...${claimedAddress.slice(-4)}`,
          status: "active",
          createdAt: FieldValue.serverTimestamp(),
        }, { merge: true });
      });
    }

    // 5. Mint Firebase custom token
    const token = await auth.createCustomToken(uid);
    return { token, uid };
  }
);
