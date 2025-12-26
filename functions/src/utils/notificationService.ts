import * as admin from "firebase-admin";

const db = admin.firestore();

interface NotificationPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
}

/**
 * Gets a user's FCM token from their profile
 */
export async function getUserFcmToken(userId: string): Promise<string | null> {
  const userDoc = await db.collection("users").doc(userId).get();
  if (!userDoc.exists) {
    return null;
  }
  const userData = userDoc.data();
  return userData?.fcmToken || null;
}

/**
 * Gets a user's full name from their profile
 */
export async function getUserFullName(userId: string): Promise<string> {
  const userDoc = await db.collection("users").doc(userId).get();
  if (!userDoc.exists) {
    return "Your partner";
  }
  const userData = userDoc.data();
  return userData?.fullName || "Your partner";
}

/**
 * Sends a push notification to a single user
 */
export async function sendNotificationToUser(
  userId: string,
  notification: NotificationPayload
): Promise<boolean> {
  const token = await getUserFcmToken(userId);
  if (!token) {
    console.log(`No FCM token found for user ${userId}`);
    return false;
  }

  try {
    await admin.messaging().send({
      token,
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: notification.data,
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    });
    console.log(`Notification sent to user ${userId}: ${notification.title}`);
    return true;
  } catch (error) {
    console.error(`Failed to send notification to user ${userId}:`, error);
    return false;
  }
}

/**
 * Sends a push notification to multiple users
 */
export async function sendNotificationToUsers(
  userIds: string[],
  notification: NotificationPayload
): Promise<void> {
  const tokens: string[] = [];

  for (const userId of userIds) {
    const token = await getUserFcmToken(userId);
    if (token) {
      tokens.push(token);
    }
  }

  if (tokens.length === 0) {
    console.log("No FCM tokens found for users");
    return;
  }

  try {
    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: notification.data,
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    });
    console.log(
      `Notifications sent: ${response.successCount} success, ` +
        `${response.failureCount} failed`
    );
  } catch (error) {
    console.error("Failed to send notifications:", error);
  }
}

// Notification message templates
export const NotificationMessages = {
  newPartnerRequest: (senderName: string) => ({
    title: "New Partner Request",
    body: `${senderName} wants to connect with you on Zawaj`,
    data: {type: "partner_request"},
  }),

  partnerRequestAccepted: (accepterName: string) => ({
    title: "Partner Request Accepted",
    body: `${accepterName} accepted your partner request! Start answering questions together.`,
    data: {type: "partner_accepted"},
  }),

  partnerCompletedQuestions: (
    partnerName: string,
    hasUserCompleted: boolean
  ) => ({
    title: `${partnerName} Completed Their Questions`,
    body: hasUserCompleted
      ? "You can now review their responses!"
      : "Answer your questions to review their responses.",
    data: {type: "partner_completed"},
  }),

  newQuestionsAvailable: () => ({
    title: "New Questions Available",
    body: "Your daily questions are ready! Start answering together.",
    data: {type: "new_questions"},
  }),

  partnerReminder: (partnerName: string) => ({
    title: "Reminder from Partner",
    body: `${partnerName} is waiting for you to answer today's questions!`,
    data: {type: "partner_reminder"},
  }),
};
