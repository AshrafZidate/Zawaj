/**
 * Bootstrap script for existing partnerships
 * Creates partnership_progress and daily_subtopic_assignments for partnerships
 * that were created before Cloud Functions were deployed
 *
 * Run with: node scripts/bootstrap-partnerships.js
 */

const admin = require("firebase-admin");

// Initialize Firebase Admin using service account key
const serviceAccount = require("../serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

function getTodayGMT() {
  const now = new Date();
  const year = now.getUTCFullYear();
  const month = String(now.getUTCMonth() + 1).padStart(2, "0");
  const day = String(now.getUTCDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function createPartnershipId(userId1, gender1, userId2, gender2) {
  const isMale1 = gender1.toLowerCase() === "male";
  const maleId = isMale1 ? userId1 : userId2;
  const femaleId = isMale1 ? userId2 : userId1;
  return `${maleId}-${femaleId}`;
}

async function calculateCombinedTopicOrder(userAPriorities, userBPriorities) {
  // Get ALL topics and filter in code to avoid composite index requirement
  const topicsSnapshot = await db.collection("topics").get();

  const allTopics = topicsSnapshot.docs.map((doc) => doc.data());

  // Separate rankable and non-rankable topics
  const rankableTopics = allTopics.filter((t) => t.is_rankable === true);
  const nonRankableTopics = allTopics
    .filter((t) => t.is_rankable === false)
    .sort((a, b) => (a.order || 0) - (b.order || 0));

  const rankableTopicIds = rankableTopics.map((t) => t.id);

  // Calculate scores for each topic
  const scores = rankableTopicIds.map((topicId) => {
    const userARank = userAPriorities.indexOf(topicId);
    const userBRank = userBPriorities.indexOf(topicId);

    const scoreA = userARank >= 0 ? 8 - userARank : 0;
    const scoreB = userBRank >= 0 ? 8 - userBRank : 0;

    return { topicId, score: scoreA + scoreB };
  });

  scores.sort((a, b) => b.score - a.score);

  const nonRankableIds = nonRankableTopics.map((t) => t.id);

  return [...scores.map((s) => s.topicId), ...nonRankableIds];
}

async function getNextSubtopic(progress) {
  // Get ALL subtopics once and filter in code to avoid composite index requirement
  const allSubtopicsSnapshot = await db.collection("subtopics").get();
  const allSubtopics = allSubtopicsSnapshot.docs.map((doc) => ({
    id: doc.data().id,
    topic_id: doc.data().topic_id,
    name: doc.data().name,
    order: doc.data().order,
  }));

  for (const topicId of progress.combined_topic_order) {
    const subtopics = allSubtopics
      .filter((s) => s.topic_id === topicId)
      .sort((a, b) => a.order - b.order);

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

async function bootstrapPartnerships() {
  console.log("Starting partnership bootstrap...\n");

  // Find all accepted partner requests
  const requestsSnapshot = await db
    .collection("partnerRequests")
    .where("status", "==", "accepted")
    .get();

  console.log(`Found ${requestsSnapshot.size} accepted partner requests\n`);

  for (const requestDoc of requestsSnapshot.docs) {
    const request = requestDoc.data();
    console.log(`Processing request: ${requestDoc.id}`);
    console.log(`  Sender: ${request.senderId}`);
    console.log(`  Receiver: ${request.receiverId}`);

    try {
      // Get both users
      const senderDoc = await db.collection("users").doc(request.senderId).get();
      const receiverDoc = await db.collection("users").doc(request.receiverId).get();

      if (!senderDoc.exists || !receiverDoc.exists) {
        console.log("  ⚠️ One or both users not found, skipping\n");
        continue;
      }

      const sender = senderDoc.data();
      const receiver = receiverDoc.data();

      // Create partnership ID
      const partnershipId = createPartnershipId(
        request.senderId,
        sender.gender,
        request.receiverId,
        receiver.gender
      );

      console.log(`  Partnership ID: ${partnershipId}`);

      // Check if partnership_progress already exists
      const progressDoc = await db
        .collection("partnership_progress")
        .doc(partnershipId)
        .get();

      if (progressDoc.exists) {
        console.log("  ✓ Partnership progress already exists");

        // Check if there's a daily assignment for today
        const today = getTodayGMT();
        const assignmentDoc = await db
          .collection("daily_subtopic_assignments")
          .doc(`${partnershipId}_${today}`)
          .get();

        if (assignmentDoc.exists) {
          console.log("  ✓ Today's assignment already exists\n");
        } else {
          // Create today's assignment
          const progress = progressDoc.data();
          const nextSubtopic = await getNextSubtopic(progress);

          if (nextSubtopic) {
            const documentId = `${partnershipId}_${today}`;
            await db.collection("daily_subtopic_assignments").doc(documentId).set({
              id: documentId.split("").reduce((a, b) => {
                a = ((a << 5) - a) + b.charCodeAt(0);
                return a & a;
              }, 0),
              partnership_id: partnershipId,
              date: today,
              subtopic_id: nextSubtopic.id,
              created_at: admin.firestore.Timestamp.now(),
              user_completion: {},
              both_completed: false,
              both_completed_at: null,
              next_assignment_scheduled: false,
              next_scheduled_date: null,
            });
            console.log(`  ✓ Created assignment for subtopic ${nextSubtopic.id} (${nextSubtopic.name})\n`);
          } else {
            console.log("  ⚠️ No subtopics found for assignment\n");
          }
        }
        continue;
      }

      // Create new partnership progress
      const combinedOrder = await calculateCombinedTopicOrder(
        sender.topicPriorities || [],
        receiver.topicPriorities || []
      );

      console.log(`  Combined topic order: ${combinedOrder.join(", ")}`);

      const newProgress = {
        id: partnershipId.split("").reduce((a, b) => {
          a = ((a << 5) - a) + b.charCodeAt(0);
          return a & a;
        }, 0),
        partnership_id: partnershipId,
        user_ids: [request.senderId, request.receiverId],
        combined_topic_order: combinedOrder,
        current_round: 1,
        completed_subtopics: [],
        is_complete: false,
        created_at: admin.firestore.Timestamp.now(),
        updated_at: admin.firestore.Timestamp.now(),
      };

      await db.collection("partnership_progress").doc(partnershipId).set(newProgress);
      console.log("  ✓ Created partnership progress");

      // Create first subtopic assignment
      const firstSubtopic = await getNextSubtopic(newProgress);

      if (firstSubtopic) {
        const today = getTodayGMT();
        const documentId = `${partnershipId}_${today}`;

        await db.collection("daily_subtopic_assignments").doc(documentId).set({
          id: documentId.split("").reduce((a, b) => {
            a = ((a << 5) - a) + b.charCodeAt(0);
            return a & a;
          }, 0),
          partnership_id: partnershipId,
          date: today,
          subtopic_id: firstSubtopic.id,
          created_at: admin.firestore.Timestamp.now(),
          user_completion: {},
          both_completed: false,
          both_completed_at: null,
          next_assignment_scheduled: false,
          next_scheduled_date: null,
        });
        console.log(`  ✓ Created assignment for subtopic ${firstSubtopic.id} (${firstSubtopic.name})\n`);
      } else {
        console.log("  ⚠️ No subtopics found for first assignment\n");
      }
    } catch (error) {
      console.log(`  ❌ Error: ${error.message}\n`);
    }
  }

  console.log("\nBootstrap complete!");
  process.exit(0);
}

bootstrapPartnerships().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
