const fs = require('fs');

// Load the question bank
const data = JSON.parse(fs.readFileSync('question_bank_v2.json', 'utf8'));

// Find all questions with branch_condition and group by parent
const followUpsByParent = {};

data.questions.forEach(q => {
    if (q.branch_condition) {
        const parentId = q.branch_condition.parent_question_id;
        if (!followUpsByParent[parentId]) {
            followUpsByParent[parentId] = [];
        }

        // Find parent to get option indices
        const parent = data.questions.find(p => p.id === parentId);
        const answerIndices = q.branch_condition.required_answers.map(ans =>
            parent.options.findIndex(opt => opt === ans)
        );

        followUpsByParent[parentId].push({
            answerIndices: answerIndices,
            questionId: q.id
        });
    }
});

console.log('Follow-ups by parent:', JSON.stringify(followUpsByParent, null, 2));

// Update questions: add follow_ups to parents, remove branch_condition from children
data.questions = data.questions.map(q => {
    // If this is a parent question, add follow_ups
    if (followUpsByParent[q.id]) {
        q.follow_ups = followUpsByParent[q.id];
        console.log(`Added follow_ups to Q${q.id}:`, q.follow_ups);
    }

    // Remove branch_condition from all questions
    if (q.branch_condition) {
        console.log(`Removed branch_condition from Q${q.id}`);
        delete q.branch_condition;
    }

    return q;
});

// Save updated data
fs.writeFileSync('question_bank_v2.json', JSON.stringify(data, null, 2));
console.log('\nSaved updated question_bank_v2.json');

// Show the updated parent questions
console.log('\n\nUpdated parent questions:');
data.questions.filter(q => q.follow_ups).forEach(q => {
    console.log(`\nQ${q.id}: ${q.question_text}`);
    console.log(`  Options: ${JSON.stringify(q.options)}`);
    console.log(`  Follow-ups: ${JSON.stringify(q.follow_ups)}`);
});
