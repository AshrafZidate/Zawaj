import * as admin from "firebase-admin";
import {getTodayGMT} from "./dateUtils";

const db = admin.firestore();

export interface PartnershipProgress {
  id: number;
  partnership_id: string;
  user_ids: string[];
  combined_topic_order: number[];
  current_round: number;
  completed_subtopics: number[];
  is_complete: boolean;
  created_at?: admin.firestore.Timestamp;
  updated_at?: admin.firestore.Timestamp;
}

export interface Subtopic {
  id: number;
  topic_id: number;
  name: string;
  order: number;
}

/**
 * Creates the partnership ID from two user IDs
 * Format: MaleId-FemaleId (sorted alphabetically if same gender)
 */
export function createPartnershipId(
  userId1: string,
  gender1: string,
  userId2: string,
  _gender2: string
): string {
  const isMale1 = gender1.toLowerCase() === "male";
  const maleId = isMale1 ? userId1 : userId2;
  const femaleId = isMale1 ? userId2 : userId1;
  return `${maleId}-${femaleId}`;
}

/**
 * Gets the next subtopic for a partnership based on their progress
 * Uses round-robin through topics at each round level
 */
export async function getNextSubtopic(
  progress: PartnershipProgress
): Promise<Subtopic | null> {
  for (const topicId of progress.combined_topic_order) {
    // Get subtopics for this topic
    const subtopicsSnapshot = await db
      .collection("subtopics")
      .where("topic_id", "==", topicId)
      .orderBy("order")
      .get();

    const subtopics = subtopicsSnapshot.docs.map((doc) => ({
      id: doc.data().id as number,
      topic_id: doc.data().topic_id as number,
      name: doc.data().name as string,
      order: doc.data().order as number,
    }));

    // Find subtopic at current round that hasn't been completed
    const subtopicAtRound = subtopics.find(
      (s) =>
        s.order === progress.current_round &&
        !progress.completed_subtopics.includes(s.id)
    );

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
export async function calculateCombinedTopicOrder(
  userAPriorities: number[],
  userBPriorities: number[]
): Promise<number[]> {
  // Get all rankable topics
  const topicsSnapshot = await db
    .collection("topics")
    .where("is_rankable", "==", true)
    .get();

  const rankableTopicIds = topicsSnapshot.docs.map(
    (doc) => doc.data().id as number
  );

  // Calculate scores for each topic
  const scores: {topicId: number; score: number}[] = rankableTopicIds.map(
    (topicId) => {
      const userARank = userAPriorities.indexOf(topicId);
      const userBRank = userBPriorities.indexOf(topicId);

      // Higher score = higher priority
      // Score = (8 - userA_rank) + (8 - userB_rank)
      const scoreA = userARank >= 0 ? 8 - userARank : 0;
      const scoreB = userBRank >= 0 ? 8 - userBRank : 0;

      return {topicId, score: scoreA + scoreB};
    }
  );

  // Sort by score descending
  scores.sort((a, b) => b.score - a.score);

  // Get non-rankable topics and append them
  const nonRankableSnapshot = await db
    .collection("topics")
    .where("is_rankable", "==", false)
    .orderBy("order")
    .get();

  const nonRankableIds = nonRankableSnapshot.docs.map(
    (doc) => doc.data().id as number
  );

  return [...scores.map((s) => s.topicId), ...nonRankableIds];
}

/**
 * Creates or gets partnership progress
 */
export async function getOrCreatePartnershipProgress(
  partnershipId: string,
  userIds: string[],
  combinedTopicOrder: number[]
): Promise<PartnershipProgress> {
  const docRef = db.collection("partnership_progress").doc(partnershipId);
  const doc = await docRef.get();

  if (doc.exists) {
    return doc.data() as PartnershipProgress;
  }

  const newProgress: PartnershipProgress = {
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
export async function createDailySubtopicAssignment(
  partnershipId: string,
  subtopicId: number,
  date?: string
): Promise<void> {
  const assignmentDate = date || getTodayGMT();
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
export async function getMaxSubtopicRound(topicIds: number[]): Promise<number> {
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
export async function incrementPartnershipRound(
  partnershipId: string
): Promise<void> {
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
export async function markPartnershipComplete(
  partnershipId: string
): Promise<void> {
  await db.collection("partnership_progress").doc(partnershipId).update({
    is_complete: true,
    updated_at: admin.firestore.Timestamp.now(),
  });
}
