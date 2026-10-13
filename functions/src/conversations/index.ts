import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

export const createConversation = onCall(
  {
    maxInstances: 15,
  },
  async (req) => {
    if (!req.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }

    const { type, recipientId, title, memberIds = [] } = req.data;
    const db = getFirestore();
    const callerId = req.auth.uid;

    if (type === "direct") {
      if (!recipientId) {
        throw new HttpsError("invalid-argument", "recipientId is required for direct chats.");
      }

      // Check if blocked
      const blockDoc1 = await db.collection("blocks").doc(`${callerId}_${recipientId}`).get();
      const blockDoc2 = await db.collection("blocks").doc(`${recipientId}_${callerId}`).get();
      if (blockDoc1.exists || blockDoc2.exists) {
        throw new HttpsError("permission-denied", "Cannot start conversation with this user.");
      }

      const sortedIds = [callerId, recipientId].sort();
      const directKey = `${sortedIds[0]}:${sortedIds[1]}`;

      // Check existing
      const existing = await db
        .collection("conversations")
        .where("directKey", "==", directKey)
        .limit(1)
        .get();

      if (!existing.empty) {
        return { conversationId: existing.docs[0].id, isNew: false };
      }

      const recipientDoc = await db.collection("users").doc(recipientId).get();
      const recipientName = recipientDoc.data()?.displayName || "User";

      const convRef = db.collection("conversations").doc();
      await convRef.set({
        id: convRef.id,
        type: "direct",
        title: recipientName,
        directKey,
        members: [callerId, recipientId],
        createdBy: callerId,
        createdAt: FieldValue.serverTimestamp(),
        lastMessageAt: FieldValue.serverTimestamp(),
      });

      return { conversationId: convRef.id, isNew: true };
    } else if (type === "group") {
      if (!title) {
        throw new HttpsError("invalid-argument", "Group title is required.");
      }

      const allMembers = Array.from(new Set([callerId, ...memberIds]));
      const convRef = db.collection("conversations").doc();
      await convRef.set({
        id: convRef.id,
        type: "group",
        title,
        members: allMembers,
        createdBy: callerId,
        createdAt: FieldValue.serverTimestamp(),
        lastMessageAt: FieldValue.serverTimestamp(),
      });

      return { conversationId: convRef.id, isNew: true };
    }

    throw new HttpsError("invalid-argument", "Invalid conversation type.");
  }
);
