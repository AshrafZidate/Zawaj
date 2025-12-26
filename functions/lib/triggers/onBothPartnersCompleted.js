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
exports.onBothPartnersCompleted = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const dateUtils_1 = require("../utils/dateUtils");
const db = admin.firestore();
/**
 * Trigger: When user_completion is updated
 * Checks if both partners have completed and schedules next assignment
 */
exports.onBothPartnersCompleted = functions.firestore
    .document("daily_subtopic_assignments/{assignmentId}")
    .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    // Skip if already both completed
    if (after.both_completed) {
        return null;
    }
    // Check if user_completion has changed
    const beforeCompletions = Object.keys(before.user_completion || {}).length;
    const afterCompletions = Object.keys(after.user_completion || {}).length;
    if (beforeCompletions === afterCompletions) {
        // No new completions, skip
        return null;
    }
    console.log(`User completion updated for assignment ${context.params.assignmentId}: ` +
        `${beforeCompletions} -> ${afterCompletions} completions`);
    // Get partnership progress to find both user IDs
    const progressDoc = await db
        .collection("partnership_progress")
        .doc(after.partnership_id)
        .get();
    if (!progressDoc.exists) {
        console.error(`Partnership progress not found: ${after.partnership_id}`);
        return null;
    }
    const progress = progressDoc.data();
    const userIds = progress?.user_ids;
    if (!userIds || userIds.length !== 2) {
        console.error(`Invalid user_ids in partnership: ${after.partnership_id}`);
        return null;
    }
    // Check if both users have completed
    const bothComplete = userIds.every((userId) => after.user_completion[userId] != null);
    if (!bothComplete) {
        console.log("Not all users have completed yet");
        return null;
    }
    console.log(`Both partners completed assignment ${context.params.assignmentId}`);
    try {
        // Calculate when the next assignment should be created
        const nextScheduledDate = (0, dateUtils_1.calculateNext12pmGMTDate)();
        console.log(`Next assignment scheduled for: ${nextScheduledDate}`);
        // Update the assignment with completion status and scheduling info
        await change.after.ref.update({
            both_completed: true,
            both_completed_at: admin.firestore.Timestamp.now(),
            next_scheduled_date: nextScheduledDate,
            next_assignment_scheduled: true,
        });
        console.log("Assignment updated with both_completed and schedule date");
        // Also mark the subtopic as completed in partnership progress
        const partnershipProgressRef = db
            .collection("partnership_progress")
            .doc(after.partnership_id);
        await partnershipProgressRef.update({
            completed_subtopics: admin.firestore.FieldValue.arrayUnion(after.subtopic_id),
            updated_at: admin.firestore.Timestamp.now(),
        });
        console.log(`Marked subtopic ${after.subtopic_id} as completed`);
        return null;
    }
    catch (error) {
        console.error("Error in onBothPartnersCompleted:", error);
        return null;
    }
});
//# sourceMappingURL=onBothPartnersCompleted.js.map