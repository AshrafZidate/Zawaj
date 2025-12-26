import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {calculateNext12pmGMTDate} from "../utils/dateUtils";
import {
  sendNotificationToUser,
  getUserFullName,
  NotificationMessages,
} from "../utils/notificationService";

const db = admin.firestore();

interface DailySubtopicAssignment {
  id: number;
  partnership_id: string;
  date: string;
  subtopic_id: number;
  created_at: admin.firestore.Timestamp;
  user_completion: Record<string, admin.firestore.Timestamp>;
  both_completed: boolean;
  both_completed_at: admin.firestore.Timestamp | null;
  next_assignment_scheduled: boolean;
  next_scheduled_date: string | null;
}

/**
 * Trigger: When user_completion is updated
 * - Notifies the other partner when one completes
 * - Checks if both partners have completed and schedules next assignment
 */
export const onBothPartnersCompleted = functions.firestore
  .document("daily_subtopic_assignments/{assignmentId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data() as DailySubtopicAssignment;
    const after = change.after.data() as DailySubtopicAssignment;

    // Skip if already both completed
    if (after.both_completed) {
      return null;
    }

    // Check if user_completion has changed
    const beforeUserIds = Object.keys(before.user_completion || {});
    const afterUserIds = Object.keys(after.user_completion || {});

    if (beforeUserIds.length === afterUserIds.length) {
      // No new completions, skip
      return null;
    }

    // Find which user just completed
    const newlyCompletedUserId = afterUserIds.find(
      (userId) => !beforeUserIds.includes(userId)
    );

    if (!newlyCompletedUserId) {
      return null;
    }

    console.log(
      `User ${newlyCompletedUserId} completed assignment ` +
        `${context.params.assignmentId}`
    );

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
    const userIds = progress?.user_ids as string[] | undefined;

    if (!userIds || userIds.length !== 2) {
      console.error(`Invalid user_ids in partnership: ${after.partnership_id}`);
      return null;
    }

    // Find the other partner
    const otherPartnerId = userIds.find((id) => id !== newlyCompletedUserId);
    if (!otherPartnerId) {
      return null;
    }

    // Check if both users have completed
    const bothComplete = userIds.every(
      (userId) => after.user_completion[userId] != null
    );

    // Get the name of the user who just completed
    const completedUserName = await getUserFullName(newlyCompletedUserId);

    if (!bothComplete) {
      // Only one user completed - notify the other partner
      const hasOtherCompleted = after.user_completion[otherPartnerId] != null;

      await sendNotificationToUser(
        otherPartnerId,
        NotificationMessages.partnerCompletedQuestions(
          completedUserName,
          hasOtherCompleted
        )
      );

      console.log(`Notified partner ${otherPartnerId} that ${completedUserName} completed`);
      return null;
    }

    // Both users have completed
    console.log(
      `Both partners completed assignment ${context.params.assignmentId}`
    );

    try {
      // Calculate when the next assignment should be created
      const nextScheduledDate = calculateNext12pmGMTDate();

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
        completed_subtopics: admin.firestore.FieldValue.arrayUnion(
          after.subtopic_id
        ),
        updated_at: admin.firestore.Timestamp.now(),
      });

      console.log(`Marked subtopic ${after.subtopic_id} as completed`);

      // Notify the other partner that both have completed (they can now review)
      await sendNotificationToUser(
        otherPartnerId,
        NotificationMessages.partnerCompletedQuestions(completedUserName, true)
      );

      return null;
    } catch (error) {
      console.error("Error in onBothPartnersCompleted:", error);
      return null;
    }
  });
