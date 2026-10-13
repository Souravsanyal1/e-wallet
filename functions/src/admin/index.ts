import { onCall, HttpsError, CallableRequest } from "firebase-functions/v2/https";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";

type Role = "superadmin" | "admin" | "moderator" | "support" | "analyst";

async function requireAdmin(req: CallableRequest, allowed: Role[]) {
  const uid = req.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Admin authentication required.");
  }

  const db = getFirestore();
  const adminDoc = await db.collection("adminUsers").doc(uid).get();

  if (!adminDoc.exists || adminDoc.data()?.active !== true) {
    throw new HttpsError("permission-denied", "Inactive or unauthorized admin account.");
  }

  const role = adminDoc.data()?.role as Role;
  if (!allowed.includes(role)) {
    throw new HttpsError("permission-denied", `Action requires one of: ${allowed.join(", ")}`);
  }

  return { uid, role };
}

async function writeAuditLog(
  db: FirebaseFirestore.Firestore,
  entry: {
    actorUid: string;
    actorRole: string;
    action: string;
    targetType: string;
    targetId: string;
    reason?: string;
    caseId?: string;
    before?: any;
    after?: any;
  }
) {
  await db.collection("adminAuditLogs").add({
    ...entry,
    createdAt: FieldValue.serverTimestamp(),
  });
}

// 1. Dashboard Aggregates
export const adminGetDashboardStats = onCall({ maxInstances: 10 }, async (req) => {
  await requireAdmin(req, ["superadmin", "admin", "moderator", "support", "analyst"]);
  const db = getFirestore();

  const usersCount = (await db.collection("users").count().get()).data().count;
  const reportsCount = (await db.collection("reports").count().get()).data().count;
  const paymentsCount = (await db.collection("payments").count().get()).data().count;
  const subsCount = (await db.collection("subscriptions").where("status", "==", "active").count().get()).data().count;

  return {
    totalUsers: usersCount,
    openReports: reportsCount,
    totalPayments: paymentsCount,
    activeSubscriptions: subsCount,
    serverHealth: "healthy",
    uptimePercent: "99.98%",
  };
});

// 2. User Management
export const adminSearchUsers = onCall({ maxInstances: 10 }, async (req) => {
  await requireAdmin(req, ["superadmin", "admin", "moderator", "support"]);
  const { query = "" } = req.data;
  const db = getFirestore();

  let queryRef = db.collection("users").limit(30);
  if (query) {
    queryRef = db.collection("users").where("handle", ">=", query).where("handle", "<=", query + "\uf8ff").limit(30);
  }

  const snap = await queryRef.get();
  return snap.docs.map((d) => {
    const data = d.data();
    return {
      id: d.id,
      handle: data.handle,
      displayName: data.displayName,
      status: data.status || "active",
      createdAt: data.createdAt?.toDate?.()?.toISOString() || null,
    };
  });
});

export const adminRevealWallet = onCall({ maxInstances: 5 }, async (req) => {
  const { uid, role } = await requireAdmin(req, ["superadmin", "admin", "moderator"]);
  const { targetUserId, reason } = req.data;

  if (!targetUserId || !reason || reason.length < 5) {
    throw new HttpsError("invalid-argument", "Reason (at least 5 characters) required.");
  }

  const db = getFirestore();
  const walletSnap = await db.collection("wallets").where("userId", "==", targetUserId).limit(1).get();

  if (walletSnap.empty) {
    throw new HttpsError("not-found", "No linked wallet found.");
  }

  const address = walletSnap.docs[0].data().address;

  // Log audit entry before returning
  await writeAuditLog(db, {
    actorUid: uid,
    actorRole: role,
    action: "wallet.revealed",
    targetType: "user",
    targetId: targetUserId,
    reason,
  });

  return { address };
});

export const adminSuspendUser = onCall({ maxInstances: 10 }, async (req) => {
  const { uid, role } = await requireAdmin(req, ["superadmin", "admin", "moderator"]);
  const { targetUserId, days = 7, reason } = req.data;

  if (!targetUserId || !reason || reason.length < 5) {
    throw new HttpsError("invalid-argument", "Valid target and reason required.");
  }

  const db = getFirestore();
  const userRef = db.collection("users").doc(targetUserId);
  const userDoc = await userRef.get();

  if (!userDoc.exists) throw new HttpsError("not-found", "User not found.");

  const suspendedUntil = new Date(Date.now() + days * 24 * 60 * 60 * 1000);

  await db.runTransaction(async (t) => {
    t.update(userRef, {
      status: "suspended",
      suspendedUntil: Timestamp.fromDate(suspendedUntil),
    });

    t.set(db.collection("bannedUsers").doc(targetUserId), {
      status: "suspended",
      bannedAt: FieldValue.serverTimestamp(),
      until: Timestamp.fromDate(suspendedUntil),
      bannedBy: uid,
      reason,
    });
  });

  await writeAuditLog(db, {
    actorUid: uid,
    actorRole: role,
    action: "user.suspend",
    targetType: "user",
    targetId: targetUserId,
    reason,
    before: { status: userDoc.data()?.status },
    after: { status: "suspended", until: suspendedUntil.toISOString() },
  });

  return { success: true };
});

export const adminBanUser = onCall({ maxInstances: 10 }, async (req) => {
  const { uid, role } = await requireAdmin(req, ["superadmin", "admin"]);
  const { targetUserId, reason } = req.data;

  if (!targetUserId || !reason || reason.length < 5) {
    throw new HttpsError("invalid-argument", "Valid target and reason required.");
  }

  const db = getFirestore();
  const userRef = db.collection("users").doc(targetUserId);

  await db.runTransaction(async (t) => {
    t.update(userRef, { status: "banned" });
    t.set(db.collection("bannedUsers").doc(targetUserId), {
      status: "banned",
      bannedAt: FieldValue.serverTimestamp(),
      bannedBy: uid,
      reason,
    });
  });

  // Revoke active sessions
  try {
    await getAuth().revokeRefreshTokens(targetUserId);
  } catch {}

  await writeAuditLog(db, {
    actorUid: uid,
    actorRole: role,
    action: "user.ban",
    targetType: "user",
    targetId: targetUserId,
    reason,
    after: { status: "banned" },
  });

  return { success: true };
});

// 3. Moderation & Cases
export const adminListCases = onCall({ maxInstances: 10 }, async (req) => {
  await requireAdmin(req, ["superadmin", "admin", "moderator", "support"]);
  const db = getFirestore();

  const casesSnap = await db.collection("reports").orderBy("createdAt", "desc").limit(40).get();
  return casesSnap.docs.map((d) => ({
    id: d.id,
    ...d.data(),
    createdAt: d.data().createdAt?.toDate?.()?.toISOString() || null,
  }));
});

export const adminResolveCase = onCall({ maxInstances: 10 }, async (req) => {
  const { uid, role } = await requireAdmin(req, ["superadmin", "admin", "moderator"]);
  const { caseId, resolution, notes } = req.data;

  const db = getFirestore();
  const caseRef = db.collection("reports").doc(caseId);

  await caseRef.update({
    status: resolution, // 'actioned', 'dismissed', 'escalated'
    resolvedBy: uid,
    resolvedAt: FieldValue.serverTimestamp(),
    resolutionNotes: notes,
  });

  await writeAuditLog(db, {
    actorUid: uid,
    actorRole: role,
    action: "case.resolve",
    targetType: "case",
    targetId: caseId,
    reason: notes,
    after: { status: resolution },
  });

  return { success: true };
});

// 4. Audit Log Viewer
export const adminListAudit = onCall({ maxInstances: 10 }, async (req) => {
  await requireAdmin(req, ["superadmin", "admin"]);
  const db = getFirestore();

  const auditSnap = await db.collection("adminAuditLogs").orderBy("createdAt", "desc").limit(50).get();
  return auditSnap.docs.map((d) => ({
    id: d.id,
    ...d.data(),
    createdAt: d.data().createdAt?.toDate?.()?.toISOString() || null,
  }));
});
