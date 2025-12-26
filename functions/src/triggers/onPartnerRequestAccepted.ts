import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {
  createPartnershipId,
  getOrCreatePartnershipProgress,
  calculateCombinedTopicOrder,
  getNextSubtopic,
  createDailySubtopicAssignment,
} from "../utils/subtopicService";

const db = admin.firestore();

interface PartnerRequest {
  id: string;
  senderId: string;
  senderFullName: string;
  senderUsername: string;
  receiverId: string;
  receiverUsername: string;
  status: string;
  createdAt: admin.firestore.Timestamp;
  respondedAt: admin.firestore.Timestamp | null;
}

interface User {
  id: string;
  gender: string;
  topicPriorities: number[];
}

/**
 * Trigger: When a partner request is accepted
 * Creates partnership progress and first subtopic assignment immediately
 */
export const onPartnerRequestAccepted = functions.firestore
  .document("partnerRequests/{requestId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data() as PartnerRequest;
    const after = change.after.data() as PartnerRequest;

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

      const sender = senderDoc.data() as User;
      const receiver = receiverDoc.data() as User;

      // Create partnership ID (MaleId-FemaleId)
      const partnershipId = createPartnershipId(
        after.senderId,
        sender.gender,
        after.receiverId,
        receiver.gender
      );

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
            const progress = await getOrCreatePartnershipProgress(
              partnershipId,
              [after.senderId, after.receiverId],
              progressData.combined_topic_order
            );

            const nextSubtopic = await getNextSubtopic(progress);

            if (nextSubtopic) {
              await createDailySubtopicAssignment(
                partnershipId,
                nextSubtopic.id
              );
              console.log(
                `Created assignment for reconnected partnership: subtopic ${nextSubtopic.id}`
              );
            }
          }
        }

        return null;
      }

      // New partnership - calculate combined topic order
      const combinedOrder = await calculateCombinedTopicOrder(
        sender.topicPriorities || [],
        receiver.topicPriorities || []
      );

      console.log(`Combined topic order: ${combinedOrder.join(", ")}`);

      // Create partnership progress
      const progress = await getOrCreatePartnershipProgress(
        partnershipId,
        [after.senderId, after.receiverId],
        combinedOrder
      );

      console.log("Partnership progress created");

      // Get and create first subtopic assignment immediately
      const firstSubtopic = await getNextSubtopic(progress);

      if (firstSubtopic) {
        await createDailySubtopicAssignment(partnershipId, firstSubtopic.id);
        console.log(
          `First assignment created: subtopic ${firstSubtopic.id} (${firstSubtopic.name})`
        );
      } else {
        console.error("No subtopics found for first assignment");
      }

      return null;
    } catch (error) {
      console.error("Error in onPartnerRequestAccepted:", error);
      return null;
    }
  });
