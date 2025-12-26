import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {
  sendNotificationToUser,
  getUserFullName,
  NotificationMessages,
} from "../utils/notificationService";

const db = admin.firestore();

const REMINDER_COOLDOWN_MS = 4 * 60 * 60 * 1000; // 4 hours in milliseconds

interface RemindPartnerRequest {
  partnershipId: string;
  partnerId: string;
}

/**
 * Callable function: Send a reminder notification to a partner
 * Can only be called once every 4 hours per partnership
 */
export const remindPartner = functions.https.onCall(
  async (data: RemindPartnerRequest, context) => {
    // Verify user is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const senderId = context.auth.uid;
    const {partnershipId, partnerId} = data;

    if (!partnershipId || !partnerId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "partnershipId and partnerId are required"
      );
    }

    console.log(
      `Remind partner request from ${senderId} to ${partnerId} ` +
        `for partnership ${partnershipId}`
    );

    try {
      // Get sender's user document to check last reminder time
      const senderDoc = await db.collection("users").doc(senderId).get();

      if (!senderDoc.exists) {
        throw new functions.https.HttpsError("not-found", "User not found");
      }

      const senderData = senderDoc.data();
      const lastReminderSentAt = senderData?.lastReminderSentAt || {};
      const lastReminderTime = lastReminderSentAt[partnershipId];

      // Check cooldown
      if (lastReminderTime) {
        const lastReminderDate = lastReminderTime.toDate
          ? lastReminderTime.toDate()
          : new Date(lastReminderTime);
        const timeSinceLastReminder = Date.now() - lastReminderDate.getTime();

        if (timeSinceLastReminder < REMINDER_COOLDOWN_MS) {
          const remainingMinutes = Math.ceil(
            (REMINDER_COOLDOWN_MS - timeSinceLastReminder) / (60 * 1000)
          );
          throw new functions.https.HttpsError(
            "failed-precondition",
            `Please wait ${remainingMinutes} minutes before sending another reminder`
          );
        }
      }

      // Get sender's name
      const senderName = await getUserFullName(senderId);

      // Send notification to partner
      const sent = await sendNotificationToUser(
        partnerId,
        NotificationMessages.partnerReminder(senderName)
      );

      if (!sent) {
        console.log(`Partner ${partnerId} has no FCM token`);
      }

      // Update last reminder time
      await db
        .collection("users")
        .doc(senderId)
        .update({
          [`lastReminderSentAt.${partnershipId}`]:
            admin.firestore.Timestamp.now(),
        });

      console.log(`Reminder sent successfully from ${senderId} to ${partnerId}`);

      return {success: true, message: "Reminder sent successfully"};
    } catch (error) {
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      console.error("Error sending reminder:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to send reminder"
      );
    }
  }
);
