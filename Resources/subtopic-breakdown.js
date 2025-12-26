const fs = require('fs');
const questions = JSON.parse(fs.readFileSync('/tmp/parsed_questions_v3.json', 'utf8'));

// Group by topic and subtopic
const breakdown = {};
questions.forEach(q => {
    const topic = q.topic || 'Unknown';
    const subtopic = q.subtopic || 'No Subtopic';
    if (!breakdown[topic]) breakdown[topic] = {};
    if (!breakdown[topic][subtopic]) breakdown[topic][subtopic] = 0;
    breakdown[topic][subtopic]++;
});

// Print breakdown
let topicNum = 1;
Object.entries(breakdown).forEach(([topic, subtopics]) => {
    const topicTotal = Object.values(subtopics).reduce((a, b) => a + b, 0);
    console.log('\n' + topicNum + '. ' + topic + ' (' + topicTotal + ' questions)');
    console.log('   ' + '-'.repeat(50));
    Object.entries(subtopics).forEach(([subtopic, count]) => {
        console.log('   ' + subtopic + ': ' + count);
    });
    topicNum++;
});

// Total
console.log('\n' + '='.repeat(60));
console.log('TOTAL: ' + questions.length + ' questions across ' +
    Object.values(breakdown).reduce((sum, t) => sum + Object.keys(t).length, 0) + ' subtopics');
