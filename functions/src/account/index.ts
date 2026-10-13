import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";

export const deleteAccount = onCall({ maxInstances: 5 }, async (req) => {
  if (!req.auth) throw new HttpsError("unauthenticated", "Authentication required.");

  const uid = req.auth.uid;
  const db = getFirestore();

  // Anonymize user profile
  await db.collection("users").doc(uid).update({
    handle: `deleted_${uid.slice(0, 6)}`,
    displayName: "Deleted User",
    avatarPath: null,
    bio: null,
    status: "deleted",
    deletedAt: FieldValue.serverTimestamp(),
  });

  // Remove auth record
  try {
    await getAuth().deleteUser(uid);
  } catch {}

  return { success: true };
});
