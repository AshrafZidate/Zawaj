import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {getTodayGMT} from "../utils/dateUtils";
import {
  getNextSubtopic,
  createDailySubtopicAssignment,
  getMaxSubtopicRound,
  incrementPartnershipRound,
  markPartnershipComplete,
  PartnershipProgress,
} from "../utils/subtopicService";
import {
  sendNotificationToUsers,
  NotificationMessages,
} from "../utils/notificationService";

const db = admin.firestore();

interface DailySubtopicAssignment {
  id: number;
  partnership_id: string;
  date: string;
  subtopic_id: number;
  both_completed: boolean;
  next_scheduled_date: string | null;
  next_assignment_scheduled: boolean;
}

/**
 * Scheduled function: Runs at 12:00 UTC (GMT) daily
 * Creates new subtopic assignments for partnerships where both completed
 */
export const dailySubtopicScheduler = functions.pubsub
  .schedule("0 12 * * *") // Every day at 12:00 UTC
  .timeZone("UTC")
  .onRun(async (_context) => {
    const today = getTodayGMT();
    console.log(`Running daily subtopic scheduler for ${today}`);

    try {
      // Find all assignments that are ready for a new subtopic
      // (both_completed = true AND next_scheduled_date = today)
      const readyAssignmentsSnapshot = await db
        .collection("daily_subtopic_assignments")
        .where("both_completed", "==", true)
        .where("next_scheduled_date", "==", today)
        .get();

      console.log(
        `Found ${readyAssignmentsSnapshot.size} partnerships ready for new assignment`
      );

      const processedPartnerships = new Set<string>();

      for (const doc of readyAssignmentsSnapshot.docs) {
        const assignment = doc.data() as DailySubtopicAssignment;

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
            console.error(
              `Partnership progress not found: ${assignment.partnership_id}`
            );
            continue;
          }

          const progress = progressDoc.data() as PartnershipProgress;

          if (progress.is_complete) {
            console.log(
              `Partnership ${assignment.partnership_id} is already complete`
            );
            continue;
          }

          // Check if there's already an assignment for today
          const existingAssignment = await db
            .collection("daily_subtopic_assignments")
            .doc(`${assignment.partnership_id}_${today}`)
            .get();

          if (existingAssignment.exists) {
            console.log(
              `Assignment already exists for ${assignment.partnership_id} on ${today}`
            );
            continue;
          }

          // Try to get the next subtopic
          let nextSubtopic = await getNextSubtopic(progress);

          // If no subtopic at current round, try incrementing rounds
          while (!nextSubtopic && !progress.is_complete) {
            const maxRound = await getMaxSubtopicRound(
              progress.combined_topic_order
            );

            if (progress.current_round < maxRound) {
              // Increment round
              await incrementPartnershipRound(assignment.partnership_id);
              progress.current_round += 1;
              nextSubtopic = await getNextSubtopic(progress);
            } else {
              // All done
              await markPartnershipComplete(assignment.partnership_id);
              progress.is_complete = true;
              console.log(
                `Partnership ${assignment.partnership_id} marked complete`
              );
            }
          }

          if (nextSubtopic) {
            // Create new assignment for today
            await createDailySubtopicAssignment(
              assignment.partnership_id,
              nextSubtopic.id,
              today
            );
            console.log(
              `Created assignment for ${assignment.partnership_id}: ` +
                `subtopic ${nextSubtopic.id}`
            );

            // Send notification to both partners
            await sendNotificationToUsers(
              progress.user_ids,
              NotificationMessages.newQuestionsAvailable()
            );
          }
        } catch (error) {
          console.error(
            `Error processing ${assignment.partnership_id}:`,
            error
          );
        }
      }

      console.log(
        `Daily scheduler completed. Processed ${processedPartnerships.size} partnerships`
      );
      return null;
    } catch (error) {
      console.error("Error in dailySubtopicScheduler:", error);
      return null;
    }
  });
