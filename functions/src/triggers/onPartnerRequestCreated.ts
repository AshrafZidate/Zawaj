import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {
  sendNotificationToUser,
  getUserFullName,
  NotificationMessages,
} from "../utils/notificationService";

const db = admin.firestore();

interface PartnerRequest {
  id: string;
  senderId: string;
  senderFullName: string;
  senderUsername: string;
  receiverId: string;
  receiverUsername: string;
  status: string;
  createdAt: admin.firestore.Timestamp;
}

/**
 * Trigger: When a new partner request is created
 * Sends a push notification to the receiver
 */
export const onPartnerRequestCreated = functions.firestore
  .document("partnerRequests/{requestId}")
  .onCreate(async (snapshot, context) => {
    const request = snapshot.data() as PartnerRequest;

    console.log(`New partner request created: ${context.params.requestId}`);

    // Get receiver's user ID from their username
    const receiverQuery = await db
      .collection("users")
      .where("username", "==", request.receiverUsername.toLowerCase())
      .limit(1)
      .get();

    if (receiverQuery.empty) {
      console.log(`Receiver not found: ${request.receiverUsername}`);
      return null;
    }

    const receiverId = receiverQuery.docs[0].id;
    const senderName = request.senderFullName || await getUserFullName(request.senderId);

    // Send notification to receiver
    await sendNotificationToUser(
      receiverId,
      NotificationMessages.newPartnerRequest(senderName)
    );

    return null;
  });
