"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.NotificationMessages = void 0;
exports.getUserFcmToken = getUserFcmToken;
exports.getUserFullName = getUserFullName;
exports.sendNotificationToUser = sendNotificationToUser;
exports.sendNotificationToUsers = sendNotificationToUsers;
const admin = __importStar(require("firebase-admin"));
const db = admin.firestore();
/**
 * Gets a user's FCM token from their profile
 */
async function getUserFcmToken(userId) {
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
async function getUserFullName(userId) {
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
async function sendNotificationToUser(userId, notification) {
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
    }
    catch (error) {
        console.error(`Failed to send notification to user ${userId}:`, error);
        return false;
    }
}
/**
 * Sends a push notification to multiple users
 */
async function sendNotificationToUsers(userIds, notification) {
    const tokens = [];
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
        console.log(`Notifications sent: ${response.successCount} success, ` +
            `${response.failureCount} failed`);
    }
    catch (error) {
        console.error("Failed to send notifications:", error);
    }
}
// Notification message templates
exports.NotificationMessages = {
    newPartnerRequest: (senderName) => ({
        title: "New Partner Request",
        body: `${senderName} wants to connect with you on Zawaj`,
        data: { type: "partner_request" },
    }),
    partnerRequestAccepted: (accepterName) => ({
        title: "Partner Request Accepted",
        body: `${accepterName} accepted your partner request! Start answering questions together.`,
        data: { type: "partner_accepted" },
    }),
    partnerCompletedQuestions: (partnerName, hasUserCompleted) => ({
        title: `${partnerName} Completed Their Questions`,
        body: hasUserCompleted
            ? "You can now review their responses!"
            : "Answer your questions to review their responses.",
        data: { type: "partner_completed" },
    }),
    newQuestionsAvailable: () => ({
        title: "New Questions Available",
        body: "Your daily questions are ready! Start answering together.",
        data: { type: "new_questions" },
    }),
    partnerReminder: (partnerName) => ({
        title: "Reminder from Partner",
        body: `${partnerName} is waiting for you to answer today's questions!`,
        data: { type: "partner_reminder" },
    }),
};
//# sourceMappingURL=notificationService.js.map