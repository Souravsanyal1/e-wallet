import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import { v2 as cloudinary } from "cloudinary";

export const uploadSign = onCall(
  {
    maxInstances: 10,
  },
  async (req) => {
    if (!req.auth) {
      throw new HttpsError("unauthenticated", "Sign in first to upload attachments.");
    }

    const { conversationId, folder = "chat_attachments" } = req.data;
    if (!conversationId) {
      throw new HttpsError("invalid-argument", "conversationId required.");
    }

    const db = getFirestore();
    const convDoc = await db.collection("conversations").doc(conversationId).get();
    if (!convDoc.exists) {
      throw new HttpsError("not-found", "Conversation not found.");
    }

    const members: string[] = convDoc.data()?.members || [];
    if (!members.includes(req.auth.uid)) {
      throw new HttpsError("permission-denied", "You are not a member of this conversation.");
    }

    const timestamp = Math.round(new Date().getTime() / 1000);
    const apiSecret = process.env.CLOUDINARY_API_SECRET || "dummy_secret_for_local";
    const apiKey = process.env.CLOUDINARY_API_KEY || "dummy_key";
    const cloudName = process.env.CLOUDINARY_CLOUD_NAME || "elitechat";

    const paramsToSign: Record<string, any> = {
      folder,
      timestamp,
    };

    const signature = cloudinary.utils.api_sign_request(paramsToSign, apiSecret);

    return {
      timestamp,
      folder,
      signature,
      apiKey,
      cloudName,
    };
  }
);
