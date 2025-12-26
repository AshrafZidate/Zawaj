const fs = require('fs');
const questions = JSON.parse(fs.readFileSync('/tmp/parsed_questions.json', 'utf8'));

console.log('=== COMPLETE IMPORT SUMMARY ===\n');
console.log('TOTAL QUESTIONS TO IMPORT: ' + questions.length + '\n');

console.log('--- BY TOPIC ---');
const byTopic = {};
questions.forEach(q => {
    const t = q.topic || 'Unknown';
    if (!byTopic[t]) byTopic[t] = { total: 0, single: 0, multi: 0, open: 0, male: 0, female: 0 };
    byTopic[t].total++;
    if (q.type === 'single_choice') byTopic[t].single++;
    else if (q.type === 'multi_choice') byTopic[t].multi++;
    else byTopic[t].open++;
    if (q.gender === 'male') byTopic[t].male++;
    if (q.gender === 'female') byTopic[t].female++;
});

let topicNum = 1;
Object.entries(byTopic).forEach(([topic, stats]) => {
    console.log('\n' + topicNum + '. ' + topic);
    console.log('   Total: ' + stats.total + ' questions');
    console.log('   Types: single_choice=' + stats.single + ', multi_choice=' + stats.multi + ', open_ended=' + stats.open);
    if (stats.male > 0 || stats.female > 0) {
        console.log('   Gender-specific: male=' + stats.male + ', female=' + stats.female);
    }
    topicNum++;
});

console.log('\n\n--- BY SUBTOPIC ---');
const bySubtopic = {};
questions.forEach(q => {
    const key = q.topic + ' > ' + (q.subtopic || 'General');
    if (!bySubtopic[key]) bySubtopic[key] = 0;
    bySubtopic[key]++;
});
Object.entries(bySubtopic).forEach(([sub, count]) => {
    console.log('  ' + sub + ': ' + count);
});

console.log('\n\n--- QUESTION TYPE SUMMARY ---');
console.log('single_choice: ' + questions.filter(q => q.type === 'single_choice').length + ' (ONLY these can trigger follow-ups)');
console.log('multi_choice: ' + questions.filter(q => q.type === 'multi_choice').length + ' ("Select all" questions - checkboxes OR free text)');
console.log('open_ended: ' + questions.filter(q => q.type === 'open_ended').length + ' (radio buttons OR free text based on user pref)');

console.log('\n\n--- SINGLE_CHOICE QUESTIONS (the 3 that trigger branching) ---');
questions.filter(q => q.type === 'single_choice').forEach((q, i) => {
    console.log((i+1) + '. ' + q.question);
    if (q.options) console.log('   Options: ' + q.options.join(' | '));
});

console.log('\n\n--- GENDER-SPECIFIC QUESTIONS ---');
console.log('\nMale-only (' + questions.filter(q => q.gender === 'male').length + ' questions):');
questions.filter(q => q.gender === 'male').forEach((q, i) => {
    console.log('  ' + (i+1) + '. ' + q.question.substring(0, 70) + (q.question.length > 70 ? '...' : ''));
});
console.log('\nFemale-only (' + questions.filter(q => q.gender === 'female').length + ' questions):');
questions.filter(q => q.gender === 'female').forEach((q, i) => {
    console.log('  ' + (i+1) + '. ' + q.question.substring(0, 70) + (q.question.length > 70 ? '...' : ''));
});

console.log('\n\n--- MULTI_CHOICE QUESTIONS (all 56) ---');
questions.filter(q => q.type === 'multi_choice').forEach((q, i) => {
    console.log((i+1) + '. ' + q.question);
});
