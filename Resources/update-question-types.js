const fs = require('fs');

// Load the question bank
const data = JSON.parse(fs.readFileSync('question_bank_v2.json', 'utf8'));

// Questions that should be open_ended (single-select with options but can be free text)
// These are questions where the options are mutually exclusive (you'd only pick one)
// but the user might want to write their own answer
const openEndedQuestionIds = [
    // Religious Values - Topic 1
    6,   // "How important is regular prayer in a spouse?" - Non-negotiable/Very important/etc
    8,   // "What role should the Qur'an play in your household?"
    9,   // "How do you view spiritual growth within marriage?"
    12,  // "Would you marry someone more practising than you?"
    13,  // "How important is halal income to you?"
    14,  // "Would you leave an income source if it was clearly haram?"
    15,  // "How do you approach modesty in dress and behaviour?"
    16,  // "How important is modesty in a spouse?"
    17,  // "How do you approach gender interaction boundaries?"
    19,  // "How important is ongoing Islamic learning after marriage?"
    20,  // "Would you like to attend Islamic learning with your spouse?"
    21,  // "How connected do you feel to your local Muslim community?"
    22,  // "How important is raising a family in a visibly Muslim environment?"
    23,  // "Would you prioritise living near a mosque?"
    24,  // "What role should a spouse play in your religious practice?"
    25,  // "How would you feel if your spouse reminded you of Islamic obligations?"
    26,  // "Should marriage make practising Islam easier?"

    // Personality - Topic 2
    49,  // "What kind of temperament do you prefer in a spouse?"

    // Lifestyle - Topic 3
    68,  // "How would you balance work and family?"

    // Marriage Roles - Topic 4
    96,  // "What does qawwam (male leadership) mean to you?"
    108, // "What does obedience in marriage mean to you?"
    109, // "When should a spouse compromise?"

    // Family - Topic 5
    147, // "What does loyalty to your spouse look like?"

    // Parenting - Topic 6
    170, // "How would you handle fertility challenges?"

    // Conflict Resolution - Topic 7
    188, // "What helps you move past conflict?"
    190, // "How do you prefer to discuss problems?"
    191, // "What communication style frustrates you most?"
    195, // "What triggers an argument for you?"
    196, // "What makes arguments worse?"
    199, // "What does genuine reconciliation look like?"
    202, // "What helps you forgive?"
    203, // "What makes forgiveness difficult?"
    206, // "What do you need from your spouse during difficult times?"
    207, // "How do you typically handle external stressors?"

    // Finances - Topic 8
    212, // "Who should manage day-to-day finances?"
    217, // "What does financial provision mean to you?"
    218, // "How do you feel about a wife contributing financially?"
    221, // "How do you approach debt?"
    222, // "What spending habits concern you?"
    224, // "What are your financial priorities?"
    227, // "What do you consider financial non-negotiables?"
    228, // "What financial behaviours would be deal-breakers?"

    // Health - Topic 9
    230, // "How do you generally manage physical health?"
    231, // "What are your diet preferences?"
    234, // "How do you currently maintain mental and emotional health?"
    238, // "How important is your spouse's involvement in your health?"
    245, // "What helps you during difficult emotional seasons?"
    254, // "How do you stay disciplined?"
    258, // "What do you need from a spouse during hardship?"
];

// Update question types
let updatedCount = 0;
data.questions.forEach(q => {
    if (openEndedQuestionIds.includes(q.id) && q.question_type === 'multi_choice') {
        q.question_type = 'open_ended';
        updatedCount++;
        console.log(`Updated Q${q.id}: ${q.question_text.substring(0, 50)}...`);
    }
});

console.log(`\nTotal questions updated: ${updatedCount}`);

// Write updated data
fs.writeFileSync('question_bank_v2.json', JSON.stringify(data, null, 2));
console.log('Saved to question_bank_v2.json');
