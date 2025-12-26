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
exports.remindPartner = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const notificationService_1 = require("../utils/notificationService");
const db = admin.firestore();
const REMINDER_COOLDOWN_MS = 4 * 60 * 60 * 1000; // 4 hours in milliseconds
/**
 * Callable function: Send a reminder notification to a partner
 * Can only be called once every 4 hours per partnership
 */
exports.remindPartner = functions.https.onCall(async (data, context) => {
    // Verify user is authenticated
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
    }
    const senderId = context.auth.uid;
    const { partnershipId, partnerId } = data;
    if (!partnershipId || !partnerId) {
        throw new functions.https.HttpsError("invalid-argument", "partnershipId and partnerId are required");
    }
    console.log(`Remind partner request from ${senderId} to ${partnerId} ` +
        `for partnership ${partnershipId}`);
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
                const remainingMinutes = Math.ceil((REMINDER_COOLDOWN_MS - timeSinceLastReminder) / (60 * 1000));
                throw new functions.https.HttpsError("failed-precondition", `Please wait ${remainingMinutes} minutes before sending another reminder`);
            }
        }
        // Get sender's name
        const senderName = await (0, notificationService_1.getUserFullName)(senderId);
        // Send notification to partner
        const sent = await (0, notificationService_1.sendNotificationToUser)(partnerId, notificationService_1.NotificationMessages.partnerReminder(senderName));
        if (!sent) {
            console.log(`Partner ${partnerId} has no FCM token`);
        }
        // Update last reminder time
        await db
            .collection("users")
            .doc(senderId)
            .update({
            [`lastReminderSentAt.${partnershipId}`]: admin.firestore.Timestamp.now(),
        });
        console.log(`Reminder sent successfully from ${senderId} to ${partnerId}`);
        return { success: true, message: "Reminder sent successfully" };
    }
    catch (error) {
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        console.error("Error sending reminder:", error);
        throw new functions.https.HttpsError("internal", "Failed to send reminder");
    }
});
//# sourceMappingURL=onRemindPartner.js.map