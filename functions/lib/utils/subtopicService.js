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
exports.createPartnershipId = createPartnershipId;
exports.getNextSubtopic = getNextSubtopic;
exports.calculateCombinedTopicOrder = calculateCombinedTopicOrder;
exports.getOrCreatePartnershipProgress = getOrCreatePartnershipProgress;
exports.createDailySubtopicAssignment = createDailySubtopicAssignment;
exports.getMaxSubtopicRound = getMaxSubtopicRound;
exports.incrementPartnershipRound = incrementPartnershipRound;
exports.markPartnershipComplete = markPartnershipComplete;
const admin = __importStar(require("firebase-admin"));
const dateUtils_1 = require("./dateUtils");
const db = admin.firestore();
/**
 * Creates the partnership ID from two user IDs
 * Format: MaleId-FemaleId (sorted alphabetically if same gender)
 */
function createPartnershipId(userId1, gender1, userId2, _gender2) {
    const isMale1 = gender1.toLowerCase() === "male";
    const maleId = isMale1 ? userId1 : userId2;
    const femaleId = isMale1 ? userId2 : userId1;
    return `${maleId}-${femaleId}`;
}
/**
 * Gets the next subtopic for a partnership based on their progress
 * Uses round-robin through topics at each round level
 */
async function getNextSubtopic(progress) {
    for (const topicId of progress.combined_topic_order) {
        // Get subtopics for this topic
        const subtopicsSnapshot = await db
            .collection("subtopics")
            .where("topic_id", "==", topicId)
            .orderBy("order")
            .get();
        const subtopics = subtopicsSnapshot.docs.map((doc) => ({
            id: doc.data().id,
            topic_id: doc.data().topic_id,
            name: doc.data().name,
            order: doc.data().order,
        }));
        // Find subtopic at current round that hasn't been completed
        const subtopicAtRound = subtopics.find((s) => s.order === progress.current_round &&
            !progress.completed_subtopics.includes(s.id));
        if (subtopicAtRound) {
            return subtopicAtRound;
        }
    }
    return null;
}
/**
 * Calculates combined topic order from two users' priorities
 * Uses weighted scoring: higher score = higher priority
 */
async function calculateCombinedTopicOrder(userAPriorities, userBPriorities) {
    // Get all rankable topics
    const topicsSnapshot = await db
        .collection("topics")
        .where("is_rankable", "==", true)
        .get();
    const rankableTopicIds = topicsSnapshot.docs.map((doc) => doc.data().id);
    // Calculate scores for each topic
    const scores = rankableTopicIds.map((topicId) => {
        const userARank = userAPriorities.indexOf(topicId);
        const userBRank = userBPriorities.indexOf(topicId);
        // Higher score = higher priority
        // Score = (8 - userA_rank) + (8 - userB_rank)
        const scoreA = userARank >= 0 ? 8 - userARank : 0;
        const scoreB = userBRank >= 0 ? 8 - userBRank : 0;
        return { topicId, score: scoreA + scoreB };
    });
    // Sort by score descending
    scores.sort((a, b) => b.score - a.score);
    // Get non-rankable topics and append them
    const nonRankableSnapshot = await db
        .collection("topics")
        .where("is_rankable", "==", false)
        .orderBy("order")
        .get();
    const nonRankableIds = nonRankableSnapshot.docs.map((doc) => doc.data().id);
    return [...scores.map((s) => s.topicId), ...nonRankableIds];
}
/**
 * Creates or gets partnership progress
 */
async function getOrCreatePartnershipProgress(partnershipId, userIds, combinedTopicOrder) {
    const docRef = db.collection("partnership_progress").doc(partnershipId);
    const doc = await docRef.get();
    if (doc.exists) {
        return doc.data();
    }
    const newProgress = {
        id: partnershipId.split("").reduce((a, b) => {
            a = ((a << 5) - a) + b.charCodeAt(0);
            return a & a;
        }, 0),
        partnership_id: partnershipId,
        user_ids: userIds,
        combined_topic_order: combinedTopicOrder,
        current_round: 1,
        completed_subtopics: [],
        is_complete: false,
        created_at: admin.firestore.Timestamp.now(),
        updated_at: admin.firestore.Timestamp.now(),
    };
    await docRef.set(newProgress);
    return newProgress;
}
/**
 * Creates a daily subtopic assignment
 */
async function createDailySubtopicAssignment(partnershipId, subtopicId, date) {
    const assignmentDate = date || (0, dateUtils_1.getTodayGMT)();
    const documentId = `${partnershipId}_${assignmentDate}`;
    await db.collection("daily_subtopic_assignments").doc(documentId).set({
        id: documentId.split("").reduce((a, b) => {
            a = ((a << 5) - a) + b.charCodeAt(0);
            return a & a;
        }, 0),
        partnership_id: partnershipId,
        date: assignmentDate,
        subtopic_id: subtopicId,
        created_at: admin.firestore.Timestamp.now(),
        user_completion: {},
        both_completed: false,
        both_completed_at: null,
        next_assignment_scheduled: false,
        next_scheduled_date: null,
    });
}
/**
 * Gets the maximum number of subtopics across all topics
 */
async function getMaxSubtopicRound(topicIds) {
    let maxCount = 0;
    for (const topicId of topicIds) {
        const subtopicsSnapshot = await db
            .collection("subtopics")
            .where("topic_id", "==", topicId)
            .get();
        maxCount = Math.max(maxCount, subtopicsSnapshot.size);
    }
    return maxCount;
}
/**
 * Increments the current round for a partnership
 */
async function incrementPartnershipRound(partnershipId) {
    await db
        .collection("partnership_progress")
        .doc(partnershipId)
        .update({
        current_round: admin.firestore.FieldValue.increment(1),
        updated_at: admin.firestore.Timestamp.now(),
    });
}
/**
 * Marks a partnership as complete
 */
async function markPartnershipComplete(partnershipId) {
    await db.collection("partnership_progress").doc(partnershipId).update({
        is_complete: true,
        updated_at: admin.firestore.Timestamp.now(),
    });
}
//# sourceMappingURL=subtopicService.js.map