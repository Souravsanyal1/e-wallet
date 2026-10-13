import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

export const onMessageCreated = onDocumentCreated(
  "conversations/{conversationId}/messages/{messageId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const message = snap.data();
    const { conversationId } = event.params;
    const db = getFirestore();
    const messaging = getMessaging();

    // 1. Update parent conversation lastMessageAt
    const convRef = db.collection("conversations").doc(conversationId);
    await convRef.update({
      lastMessageAt: FieldValue.serverTimestamp(),
      lastMessagePreview: message.kind === "text" ? message.content : "[Attachment]",
    });

    // 2. Fetch conversation members to send push
    const convDoc = await convRef.get();
    if (!convDoc.exists) return;

    const members: string[] = convDoc.data()?.members || [];
    const recipients = members.filter((m) => m !== message.senderId);

    for (const recipientId of recipients) {
      const tokensSnap = await db
        .collection("users")
        .doc(recipientId)
        .collection("deviceTokens")
        .get();

      const tokens = tokensSnap.docs.map((d) => d.id);
      if (tokens.length === 0) continue;

      // Privacy-safe generic push notification payload per security.md
      await messaging.sendEachForMulticast({
        tokens,
        notification: {
          title: "New Message",
          body: "You have received a new secure message on EliteChat",
        },
        data: {
          conversationId,
          type: "message",
        },
      });
    }
  }
);
