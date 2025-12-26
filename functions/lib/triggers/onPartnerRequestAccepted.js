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
exports.onPartnerRequestAccepted = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const subtopicService_1 = require("../utils/subtopicService");
const db = admin.firestore();
/**
 * Trigger: When a partner request is accepted
 * Creates partnership progress and first subtopic assignment immediately
 */
exports.onPartnerRequestAccepted = functions.firestore
    .document("partnerRequests/{requestId}")
    .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    // Only trigger when status changes to "accepted"
    if (before.status === "accepted" || after.status !== "accepted") {
        return null;
    }
    console.log(`Partner request ${context.params.requestId} accepted`);
    try {
        // Get both users
        const senderDoc = await db.collection("users").doc(after.senderId).get();
        const receiverDoc = await db
            .collection("users")
            .doc(after.receiverId)
            .get();
        if (!senderDoc.exists || !receiverDoc.exists) {
            console.error("One or both users not found");
            return null;
        }
        const sender = senderDoc.data();
        const receiver = receiverDoc.data();
        // Create partnership ID (MaleId-FemaleId)
        const partnershipId = (0, subtopicService_1.createPartnershipId)(after.senderId, sender.gender, after.receiverId, receiver.gender);
        console.log(`Partnership ID: ${partnershipId}`);
        // Check if partnership progress already exists (reconnection case)
        const existingProgress = await db
            .collection("partnership_progress")
            .doc(partnershipId)
            .get();
        if (existingProgress.exists) {
            console.log("Partnership progress already exists - reconnection case");
            // For reconnection, check if there's an active assignment
            // If not, we need to create one based on current progress
            const progressData = existingProgress.data();
            if (progressData && !progressData.is_complete) {
                // Check for existing incomplete assignment
                const assignmentsSnapshot = await db
                    .collection("daily_subtopic_assignments")
                    .where("partnership_id", "==", partnershipId)
                    .where("both_completed", "==", false)
                    .limit(1)
                    .get();
                if (assignmentsSnapshot.empty) {
                    // Need to create a new assignment
                    const progress = await (0, subtopicService_1.getOrCreatePartnershipProgress)(partnershipId, [after.senderId, after.receiverId], progressData.combined_topic_order);
                    const nextSubtopic = await (0, subtopicService_1.getNextSubtopic)(progress);
                    if (nextSubtopic) {
                        await (0, subtopicService_1.createDailySubtopicAssignment)(partnershipId, nextSubtopic.id);
                        console.log(`Created assignment for reconnected partnership: subtopic ${nextSubtopic.id}`);
                    }
                }
            }
            return null;
        }
        // New partnership - calculate combined topic order
        const combinedOrder = await (0, subtopicService_1.calculateCombinedTopicOrder)(sender.topicPriorities || [], receiver.topicPriorities || []);
        console.log(`Combined topic order: ${combinedOrder.join(", ")}`);
        // Create partnership progress
        const progress = await (0, subtopicService_1.getOrCreatePartnershipProgress)(partnershipId, [after.senderId, after.receiverId], combinedOrder);
        console.log("Partnership progress created");
        // Get and create first subtopic assignment immediately
        const firstSubtopic = await (0, subtopicService_1.getNextSubtopic)(progress);
        if (firstSubtopic) {
            await (0, subtopicService_1.createDailySubtopicAssignment)(partnershipId, firstSubtopic.id);
            console.log(`First assignment created: subtopic ${firstSubtopic.id} (${firstSubtopic.name})`);
        }
        else {
            console.error("No subtopics found for first assignment");
        }
        return null;
    }
    catch (error) {
        console.error("Error in onPartnerRequestAccepted:", error);
        return null;
    }
});
//# sourceMappingURL=onPartnerRequestAccepted.js.map