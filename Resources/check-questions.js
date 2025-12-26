const fs = require('fs');

const data = JSON.parse(fs.readFileSync('question_bank_v2.json', 'utf8'));

// Group questions by topic
const topicQuestions = {};
data.questions.forEach(q => {
    const subtopic = data.subtopics.find(s => s.id === q.subtopic_id);
    const topic = data.topics.find(t => t.id === subtopic?.topic_id);
    const topicName = topic?.name || 'Unknown';
    if (!topicQuestions[topicName]) topicQuestions[topicName] = [];
    topicQuestions[topicName].push(q);
});

console.log('Questions per topic in database:');
Object.entries(topicQuestions).forEach(([topic, qs]) => {
    console.log(`  ${topic}: ${qs.length} questions`);
});
console.log(`\nTotal: ${data.questions.length} questions`);
console.log(`Topics: ${data.topics.length}`);
console.log(`Subtopics: ${data.subtopics.length}`);

// Show first 10 questions
console.log('\nFirst 10 questions:');
data.questions.slice(0, 10).forEach(q => {
    console.log(`Q${q.id}: ${q.question_text.substring(0, 60)}...`);
});

// Show last 10 questions
console.log('\nLast 10 questions:');
data.questions.slice(-10).forEach(q => {
    console.log(`Q${q.id}: ${q.question_text.substring(0, 60)}...`);
});
