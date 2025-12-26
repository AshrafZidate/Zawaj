/**
 * Check questions in Firestore
 */

const admin = require("firebase-admin");
const serviceAccount = require("../serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function checkData() {
  console.log("=== Checking Firestore Data ===\n");

  // Check topics
  const topicsSnapshot = await db.collection("topics").get();
  console.log(`Topics: ${topicsSnapshot.size} documents`);
  topicsSnapshot.docs.forEach(doc => {
    const data = doc.data();
    console.log(`  - ID: ${data.id}, Name: ${data.name}, Order: ${data.order}, Rankable: ${data.is_rankable}`);
  });

  // Check subtopics
  console.log("\n");
  const subtopicsSnapshot = await db.collection("subtopics").get();
  console.log(`Subtopics: ${subtopicsSnapshot.size} documents`);
  subtopicsSnapshot.docs.slice(0, 5).forEach(doc => {
    const data = doc.data();
    console.log(`  - ID: ${data.id}, TopicID: ${data.topic_id}, Name: ${data.name}, Order: ${data.order}`);
  });
  if (subtopicsSnapshot.size > 5) {
    console.log(`  ... and ${subtopicsSnapshot.size - 5} more`);
  }

  // Check questions
  console.log("\n");
  const questionsSnapshot = await db.collection("questions").get();
  console.log(`Questions: ${questionsSnapshot.size} documents`);

  // Show questions for subtopic 1
  const subtopic1Questions = questionsSnapshot.docs.filter(doc => doc.data().subtopic_id === 1);
  console.log(`\nQuestions for subtopic 1 (Core Relationship With Islam): ${subtopic1Questions.length}`);
  subtopic1Questions.forEach(doc => {
    const data = doc.data();
    console.log(`  - ID: ${data.id}, Order: ${data.order}, Type: ${data.question_type}`);
    console.log(`    Text: ${data.question_text?.substring(0, 60)}...`);
    console.log(`    Gender: ${data.gender}, ArchivedAt: ${data.archived_at}`);
    console.log(`    Has 'archived_at' key: ${'archived_at' in data}`);
    console.log(`    archived_at === null: ${data.archived_at === null}`);
    console.log(`    archived_at === undefined: ${data.archived_at === undefined}`);
  });

  // Check daily_subtopic_assignments
  console.log("\n");
  const assignmentsSnapshot = await db.collection("daily_subtopic_assignments").get();
  console.log(`Daily Subtopic Assignments: ${assignmentsSnapshot.size} documents`);
  assignmentsSnapshot.docs.forEach(doc => {
    const data = doc.data();
    console.log(`  - ${doc.id}: SubtopicID=${data.subtopic_id}, BothCompleted=${data.both_completed}`);
  });

  // Check partnership_progress
  console.log("\n");
  const progressSnapshot = await db.collection("partnership_progress").get();
  console.log(`Partnership Progress: ${progressSnapshot.size} documents`);
  progressSnapshot.docs.forEach(doc => {
    const data = doc.data();
    console.log(`  - ${doc.id}: Round=${data.current_round}, Complete=${data.is_complete}`);
    console.log(`    CompletedSubtopics: ${data.completed_subtopics?.length || 0}`);
  });

  process.exit(0);
}

checkData().catch(err => {
  console.error("Error:", err);
  process.exit(1);
});
