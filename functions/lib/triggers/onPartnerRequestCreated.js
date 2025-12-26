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
exports.onPartnerRequestCreated = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const notificationService_1 = require("../utils/notificationService");
const db = admin.firestore();
/**
 * Trigger: When a new partner request is created
 * Sends a push notification to the receiver
 */
exports.onPartnerRequestCreated = functions.firestore
    .document("partnerRequests/{requestId}")
    .onCreate(async (snapshot, context) => {
    const request = snapshot.data();
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
    const senderName = request.senderFullName || await (0, notificationService_1.getUserFullName)(request.senderId);
    // Send notification to receiver
    await (0, notificationService_1.sendNotificationToUser)(receiverId, notificationService_1.NotificationMessages.newPartnerRequest(senderName));
    return null;
});
//# sourceMappingURL=onPartnerRequestCreated.js.map