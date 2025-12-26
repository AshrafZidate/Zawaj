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
exports.dailySubtopicScheduler = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const dateUtils_1 = require("../utils/dateUtils");
const subtopicService_1 = require("../utils/subtopicService");
const db = admin.firestore();
/**
 * Scheduled function: Runs at 12:00 UTC (GMT) daily
 * Creates new subtopic assignments for partnerships where both completed
 */
exports.dailySubtopicScheduler = functions.pubsub
    .schedule("0 12 * * *") // Every day at 12:00 UTC
    .timeZone("UTC")
    .onRun(async (_context) => {
    const today = (0, dateUtils_1.getTodayGMT)();
    console.log(`Running daily subtopic scheduler for ${today}`);
    try {
        // Find all assignments that are ready for a new subtopic
        // (both_completed = true AND next_scheduled_date = today)
        const readyAssignmentsSnapshot = await db
            .collection("daily_subtopic_assignments")
            .where("both_completed", "==", true)
            .where("next_scheduled_date", "==", today)
            .get();
        console.log(`Found ${readyAssignmentsSnapshot.size} partnerships ready for new assignment`);
        const processedPartnerships = new Set();
        for (const doc of readyAssignmentsSnapshot.docs) {
            const assignment = doc.data();
            // Skip if we already processed this partnership (could have multiple)
            if (processedPartnerships.has(assignment.partnership_id)) {
                continue;
            }
            processedPartnerships.add(assignment.partnership_id);
            console.log(`Processing partnership: ${assignment.partnership_id}`);
            try {
                // Get partnership progress
                const progressDoc = await db
                    .collection("partnership_progress")
                    .doc(assignment.partnership_id)
                    .get();
                if (!progressDoc.exists) {
                    console.error(`Partnership progress not found: ${assignment.partnership_id}`);
                    continue;
                }
                const progress = progressDoc.data();
                if (progress.is_complete) {
                    console.log(`Partnership ${assignment.partnership_id} is already complete`);
                    continue;
                }
                // Check if there's already an assignment for today
                const existingAssignment = await db
                    .collection("daily_subtopic_assignments")
                    .doc(`${assignment.partnership_id}_${today}`)
                    .get();
                if (existingAssignment.exists) {
                    console.log(`Assignment already exists for ${assignment.partnership_id} on ${today}`);
                    continue;
                }
                // Try to get the next subtopic
                let nextSubtopic = await (0, subtopicService_1.getNextSubtopic)(progress);
                // If no subtopic at current round, try incrementing rounds
                while (!nextSubtopic && !progress.is_complete) {
                    const maxRound = await (0, subtopicService_1.getMaxSubtopicRound)(progress.combined_topic_order);
                    if (progress.current_round < maxRound) {
                        // Increment round
                        await (0, subtopicService_1.incrementPartnershipRound)(assignment.partnership_id);
                        progress.current_round += 1;
                        nextSubtopic = await (0, subtopicService_1.getNextSubtopic)(progress);
                    }
                    else {
                        // All done
                        await (0, subtopicService_1.markPartnershipComplete)(assignment.partnership_id);
                        progress.is_complete = true;
                        console.log(`Partnership ${assignment.partnership_id} marked complete`);
                    }
                }
                if (nextSubtopic) {
                    // Create new assignment for today
                    await (0, subtopicService_1.createDailySubtopicAssignment)(assignment.partnership_id, nextSubtopic.id, today);
                    console.log(`Created assignment for ${assignment.partnership_id}: ` +
                        `subtopic ${nextSubtopic.id}`);
                }
            }
            catch (error) {
                console.error(`Error processing ${assignment.partnership_id}:`, error);
            }
        }
        console.log(`Daily scheduler completed. Processed ${processedPartnerships.size} partnerships`);
        return null;
    }
    catch (error) {
        console.error("Error in dailySubtopicScheduler:", error);
        return null;
    }
});
//# sourceMappingURL=dailySubtopicScheduler.js.map