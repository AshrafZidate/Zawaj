const fs = require('fs');
const questions = JSON.parse(fs.readFileSync('/tmp/parsed_questions_v3.json', 'utf8'));

console.log('=== COMPLETE IMPORT SUMMARY ===\n');
console.log('TOTAL QUESTIONS TO IMPORT: ' + questions.length + '\n');

console.log('--- BY TOPIC ---');
const byTopic = {};
questions.forEach(q => {
    const t = q.topic || 'Unknown';
    if (!byTopic[t]) byTopic[t] = { total: 0, single: 0, multi: 0, open: 0, male: 0, female: 0, subtopics: new Set() };
    byTopic[t].total++;
    if (q.type === 'single_choice') byTopic[t].single++;
    else if (q.type === 'multi_choice') byTopic[t].multi++;
    else byTopic[t].open++;
    if (q.gender === 'male') byTopic[t].male++;
    if (q.gender === 'female') byTopic[t].female++;
    if (q.subtopic) byTopic[t].subtopics.add(q.subtopic);
});

let topicNum = 1;
Object.entries(byTopic).forEach(([topic, stats]) => {
    console.log('\n' + topicNum + '. ' + topic);
    console.log('   Questions: ' + stats.total);
    console.log('   Subtopics: ' + stats.subtopics.size);
    console.log('   Types: single=' + stats.single + ', multi=' + stats.multi + ', open=' + stats.open);
    if (stats.male > 0 || stats.female > 0) {
        console.log('   Gender: male=' + stats.male + ', female=' + stats.female);
    }
    topicNum++;
});

console.log('\n\n--- QUESTION TYPE TOTALS ---');
console.log('single_choice: ' + questions.filter(q => q.type === 'single_choice').length + ' (ONLY these trigger follow-ups)');
console.log('multi_choice: ' + questions.filter(q => q.type === 'multi_choice').length + ' ("Select all" questions)');
console.log('open_ended: ' + questions.filter(q => q.type === 'open_ended').length + ' (all other questions)');

console.log('\n\n--- ALL MULTI_CHOICE QUESTIONS (' + questions.filter(q => q.type === 'multi_choice').length + ') ---');
questions.filter(q => q.type === 'multi_choice').forEach((q, i) => {
    console.log((i+1) + '. ' + q.question);
});

console.log('\n\n--- GENDER-SPECIFIC QUESTIONS ---');
console.log('\nMale-only (' + questions.filter(q => q.gender === 'male').length + '):');
questions.filter(q => q.gender === 'male').forEach((q, i) => {
    console.log('  ' + (i+1) + '. ' + q.question.substring(0, 80));
});
console.log('\nFemale-only (' + questions.filter(q => q.gender === 'female').length + '):');
questions.filter(q => q.gender === 'female').forEach((q, i) => {
    console.log('  ' + (i+1) + '. ' + q.question.substring(0, 80));
});
