const fs = require('fs');

// Load parsed questions
const questions = JSON.parse(fs.readFileSync('/tmp/parsed_questions_v3.json', 'utf8'));

// Topic-subtopic mapping with IDs
const topicsData = [
    { id: 1, name: "Religious Values", order: 1, is_rankable: true },
    { id: 2, name: "Personality and Emotional Compatibility", order: 2, is_rankable: true },
    { id: 3, name: "Lifestyle and Long-Term Goals", order: 3, is_rankable: true },
    { id: 4, name: "Views on Marriage Roles and Responsibilities", order: 4, is_rankable: true },
    { id: 5, name: "Family Expectations, In-Laws, and Boundaries", order: 5, is_rankable: true },
    { id: 6, name: "Parenting, Children, and Family Building", order: 6, is_rankable: true },
    { id: 7, name: "Conflict Resolution, Disagreements, and Repair", order: 7, is_rankable: true },
    { id: 8, name: "Finances, Provision, and Money Attitudes", order: 8, is_rankable: true },
    { id: 9, name: "Health, Well-being, and Personal Growth", order: 9, is_rankable: false },
    { id: 10, name: "Understanding the Woman's Menstrual Cycle", order: 10, is_rankable: false }
];

const subtopicsData = [
    // Topic 1: Religious Values
    { id: 1, topic_id: 1, name: "Core Relationship With Islam", order: 1 },
    { id: 2, topic_id: 1, name: "Practice and Daily Worship", order: 2 },
    { id: 3, topic_id: 1, name: "Growth, Intentions, and Direction", order: 3 },
    { id: 4, topic_id: 1, name: "Halal, Haram, and Boundaries", order: 4 },
    { id: 5, topic_id: 1, name: "Islamic Knowledge and Learning", order: 5 },
    { id: 6, topic_id: 1, name: "Community, Environment, and Identity", order: 6 },
    { id: 7, topic_id: 1, name: "Marriage, Deen, and Expectations", order: 7 },
    { id: 8, topic_id: 1, name: "Differences and Deal-Breakers", order: 8 },

    // Topic 2: Personality and Emotional Compatibility
    { id: 9, topic_id: 2, name: "Emotional Needs and Connection", order: 1 },
    { id: 10, topic_id: 2, name: "Stress, Pressure, and Regulation", order: 2 },
    { id: 11, topic_id: 2, name: "Communication Style", order: 3 },
    { id: 12, topic_id: 2, name: "Affection and Reassurance", order: 4 },
    { id: 13, topic_id: 2, name: "Temperament and Personality Fit", order: 5 },
    { id: 14, topic_id: 2, name: "Conflict Triggers and Repair", order: 6 },
    { id: 15, topic_id: 2, name: "Emotional Maturity and Trust", order: 7 },

    // Topic 3: Lifestyle and Long-Term Goals
    { id: 16, topic_id: 3, name: "Day-to-Day Lifestyle Alignment", order: 1 },
    { id: 17, topic_id: 3, name: "Social Life and Balance", order: 2 },
    { id: 18, topic_id: 3, name: "Work, Ambition, and Time Priorities", order: 3 },
    { id: 19, topic_id: 3, name: "Financial Lifestyle (Living Style)", order: 4 },
    { id: 20, topic_id: 3, name: "Location, Living Arrangements, and Mobility", order: 5 },
    { id: 21, topic_id: 3, name: "Pace of Life and Energy Levels", order: 6 },
    { id: 22, topic_id: 3, name: "Planning vs Flexibility", order: 7 },
    { id: 23, topic_id: 3, name: "Travel, Downtime, and Enjoyment", order: 8 },
    { id: 24, topic_id: 3, name: "Seasons of Life and Change", order: 9 },
    { id: 25, topic_id: 3, name: "Expectations of Marriage and the Future", order: 10 },
    { id: 26, topic_id: 3, name: "Deal-Breakers and Flexibility", order: 11 },

    // Topic 4: Views on Marriage Roles and Responsibilities
    { id: 27, topic_id: 4, name: "Core View of Marriage Roles", order: 1 },
    { id: 28, topic_id: 4, name: "Leadership, Authority, and Decision-Making", order: 2 },
    { id: 29, topic_id: 4, name: "Domestic Responsibilities", order: 3 },
    { id: 30, topic_id: 4, name: "Independence and Personal Space", order: 4 },
    { id: 31, topic_id: 4, name: "Obedience, Compromise, and Flexibility", order: 5 },
    { id: 32, topic_id: 4, name: "Gender Expectations and Cultural Influence", order: 6 },
    { id: 33, topic_id: 4, name: "Respect, Boundaries, and Mutual Regard", order: 7 },
    { id: 34, topic_id: 4, name: "Children and Role Modelling", order: 8 },
    { id: 35, topic_id: 4, name: "Deal-Breakers and Clarity", order: 9 },

    // Topic 5: Family Expectations, In-Laws, and Boundaries
    { id: 36, topic_id: 5, name: "Importance of Family", order: 1 },
    { id: 37, topic_id: 5, name: "Parental Influence and Authority", order: 2 },
    { id: 38, topic_id: 5, name: "Living Arrangements and Proximity", order: 3 },
    { id: 39, topic_id: 5, name: "In-Law Relationships", order: 4 },
    { id: 40, topic_id: 5, name: "Boundaries and Privacy", order: 5 },
    { id: 41, topic_id: 5, name: "Conflict Involving Family", order: 6 },
    { id: 42, topic_id: 5, name: "Cultural Expectations and Pressure", order: 7 },
    { id: 43, topic_id: 5, name: "Siblings and Wider Family", order: 8 },
    { id: 44, topic_id: 5, name: "Loyalty, Prioritisation, and Unity", order: 9 },
    { id: 45, topic_id: 5, name: "Scenarios and Reality Checks", order: 10 },
    { id: 46, topic_id: 5, name: "Deal-Breakers and Clarity", order: 11 },

    // Topic 6: Parenting, Children, and Family Building
    { id: 47, topic_id: 6, name: "Desire for Children", order: 1 },
    { id: 48, topic_id: 6, name: "Parenting Philosophy and Values", order: 2 },
    { id: 49, topic_id: 6, name: "Discipline and Boundaries", order: 3 },
    { id: 50, topic_id: 6, name: "Roles, Sacrifices, and Responsibility", order: 4 },
    { id: 51, topic_id: 6, name: "Emotional Readiness and Patience", order: 5 },
    { id: 52, topic_id: 6, name: "Health, Fertility, and Reality Scenarios", order: 6 },
    { id: 53, topic_id: 6, name: "Environment and Upbringing", order: 7 },
    { id: 54, topic_id: 6, name: "Boundaries and External Influence", order: 8 },
    { id: 55, topic_id: 6, name: "Long-Term Vision and Deal-Breakers", order: 9 },

    // Topic 7: Conflict Resolution, Disagreements, and Repair
    { id: 56, topic_id: 7, name: "Core Conflict Orientation", order: 1 },
    { id: 57, topic_id: 7, name: "Emotional Regulation During Conflict", order: 2 },
    { id: 58, topic_id: 7, name: "Timing, Space, and Processing", order: 3 },
    { id: 59, topic_id: 7, name: "Communication Under Disagreement", order: 4 },
    { id: 60, topic_id: 7, name: "Apologies, Accountability, and Repair", order: 5 },
    { id: 61, topic_id: 7, name: "Patterns, Triggers, and Escalation", order: 6 },
    { id: 62, topic_id: 7, name: "Silent Treatment, Avoidance, and Pausing", order: 7 },
    { id: 63, topic_id: 7, name: "Seeking Help and Support", order: 8 },
    { id: 64, topic_id: 7, name: "Learning From Conflict", order: 9 },
    { id: 65, topic_id: 7, name: "Scenarios and Safety", order: 10 },

    // Topic 8: Finances, Provision, and Money Attitudes
    { id: 66, topic_id: 8, name: "Core Money Mindset", order: 1 },
    { id: 67, topic_id: 8, name: "Provision and Responsibility", order: 2 },
    { id: 68, topic_id: 8, name: "Spending, Saving, Lifestyle", order: 3 },
    { id: 69, topic_id: 8, name: "Shared vs Separate Finances", order: 4 },
    { id: 70, topic_id: 8, name: "Debt, Risk, and Responsibility", order: 5 },
    { id: 71, topic_id: 8, name: "Financial Stress and Conflict", order: 6 },
    { id: 72, topic_id: 8, name: "Work, Sacrifice, Trade-Offs", order: 7 },
    { id: 73, topic_id: 8, name: "Generosity, Zakat, Giving", order: 8 },
    { id: 74, topic_id: 8, name: "Future Planning and Deal-Breakers", order: 9 },

    // Topic 9: Health, Well-being, and Personal Growth
    { id: 75, topic_id: 9, name: "Overall Health Orientation", order: 1 },
    { id: 76, topic_id: 9, name: "Physical Health Habits", order: 2 },
    { id: 77, topic_id: 9, name: "Mental and Emotional Well-being", order: 3 },
    { id: 78, topic_id: 9, name: "Support and Expectations in Marriage", order: 4 },
    { id: 79, topic_id: 9, name: "Boundaries, Capacity, Burnout", order: 5 },
    { id: 80, topic_id: 9, name: "Healing, Past Experiences, Growth", order: 6 },
    { id: 81, topic_id: 9, name: "Seeking Help and Support Systems", order: 7 },
    { id: 82, topic_id: 9, name: "Growth Mindset in Marriage", order: 8 },
    { id: 83, topic_id: 9, name: "Habits, Discipline, Consistency", order: 9 },
    { id: 84, topic_id: 9, name: "Difficult Seasons and Sustainability", order: 10 },

    // Topic 10: Understanding the Woman's Menstrual Cycle
    { id: 85, topic_id: 10, name: "Men's Version (Husband Perspective)", order: 1 },
    { id: 86, topic_id: 10, name: "Women's Version (Wife Perspective)", order: 2 }
];

// Create lookup maps
const topicByName = {};
topicsData.forEach(t => topicByName[t.name] = t);

const subtopicByName = {};
subtopicsData.forEach(s => {
    const topic = topicsData.find(t => t.id === s.topic_id);
    const key = topic.name + '|' + s.name;
    subtopicByName[key] = s;
});

// Track question order within each subtopic
const subtopicOrderCounter = {};

// Convert parsed questions to database format
const questionsData = [];
let questionId = 1;

questions.forEach(q => {
    const topic = topicByName[q.topic];
    if (!topic) {
        console.error('Unknown topic:', q.topic);
        return;
    }

    const subtopicKey = q.topic + '|' + q.subtopic;
    const subtopic = subtopicByName[subtopicKey];
    if (!subtopic) {
        console.error('Unknown subtopic:', q.subtopic, 'in topic:', q.topic);
        return;
    }

    // Track order within subtopic
    if (!subtopicOrderCounter[subtopic.id]) {
        subtopicOrderCounter[subtopic.id] = 0;
    }
    subtopicOrderCounter[subtopic.id]++;

    const questionData = {
        id: questionId,
        subtopic_id: subtopic.id,
        question_text: q.question,
        question_type: q.type,
        options: q.options || [],
        order: subtopicOrderCounter[subtopic.id],
        gender: q.gender || null
    };

    questionsData.push(questionData);
    questionId++;
});

// Now add follow_ups to the 3 single_choice parent questions
// Question 2: "How do you feel about where you are religiously at this stage of life?"
//   -> Follow-up Q3: "If you feel unsettled religiously, what best explains why?"
//      Triggered by: "Mostly content with some concern" (index 1), "Not content and struggling" (index 2), "Unsure or conflicted" (index 3)

// Question 4: "How often do you pray the five daily prayers?"
//   -> Follow-up Q5: "If you miss prayers, what is the most common reason?"
//      Triggered by: "Most days" (index 1), "Occasionally" (index 2), "Rarely" (index 3)

// Find "Do you want children?" and its follow-ups
// The follow-ups depend on answers and are more complex

// Find the specific questions
const q2 = questionsData.find(q => q.question_text.includes("How do you feel about where you are religiously"));
const q3 = questionsData.find(q => q.question_text.includes("If you feel unsettled religiously"));
const q4 = questionsData.find(q => q.question_text.includes("How often do you pray the five daily prayers"));
const q5 = questionsData.find(q => q.question_text.includes("If you miss prayers"));
const qChildren = questionsData.find(q => q.question_text === "Do you want children?");

// Find all "Do you want children?" follow-ups based on the Word doc structure
// Looking at the parsed questions for follow-ups after "Do you want children?"
const childrenFollowUps = [];
questions.forEach((q, idx) => {
    // These are the follow-up patterns based on Word doc
    if (q.question.includes("If you answered") ||
        q.question.includes("not possible") ||
        q.question.includes("do not have a strong desire")) {
        const dbQ = questionsData.find(dbq => dbq.question_text === q.question);
        if (dbQ) childrenFollowUps.push(dbQ);
    }
});

console.log('Found parent questions:');
console.log('Q2 (religious feeling):', q2 ? q2.id : 'NOT FOUND');
console.log('Q3 (unsettled follow-up):', q3 ? q3.id : 'NOT FOUND');
console.log('Q4 (prayer frequency):', q4 ? q4.id : 'NOT FOUND');
console.log('Q5 (miss prayers follow-up):', q5 ? q5.id : 'NOT FOUND');
console.log('Q Children:', qChildren ? qChildren.id : 'NOT FOUND');
console.log('Children follow-ups found:', childrenFollowUps.length);

// Add follow_ups to parent questions
if (q2 && q3) {
    q2.follow_ups = [{
        answerIndices: [1, 2, 3],  // "Mostly content with some concern", "Not content and struggling", "Unsure or conflicted"
        questionId: q3.id
    }];
}

if (q4 && q5) {
    q4.follow_ups = [{
        answerIndices: [1, 2, 3],  // "Most days", "Occasionally", "Rarely"
        questionId: q5.id
    }];
}

// For "Do you want children?" - find the follow-ups
// Options: "Yes" (0), "No" (1), "I am open to them" (2), "I am unsure" (3)
if (qChildren) {
    // Normalize quotes for matching (handles U+201C/U+201D curly quotes)
    function normalizeQuotes(str) {
        return str.replace(/[\u201C\u201D]/g, '"').replace(/[\u2018\u2019]/g, "'");
    }

    // Find specific follow-up questions
    const noFollowUp = questionsData.find(q =>
        normalizeQuotes(q.question_text).includes('If you answered "No"')
    );
    const openFollowUp = questionsData.find(q =>
        normalizeQuotes(q.question_text).includes('If you answered "Open"')
    );
    const unsureFollowUp = questionsData.find(q =>
        normalizeQuotes(q.question_text).includes('If "Unsure"')
    );

    const followUps = [];

    // "No" triggers "If you answered 'No', why not?"
    if (noFollowUp) {
        followUps.push({
            answerIndices: [1],  // "No" is index 1
            questionId: noFollowUp.id
        });
        console.log('  No follow-up: Q' + noFollowUp.id + ' - ' + noFollowUp.question_text.substring(0, 40));
    }

    // "I am open to them" triggers "If you answered 'Open', which is closest?"
    if (openFollowUp) {
        followUps.push({
            answerIndices: [2],  // "I am open to them" is index 2
            questionId: openFollowUp.id
        });
        console.log('  Open follow-up: Q' + openFollowUp.id + ' - ' + openFollowUp.question_text.substring(0, 40));
    }

    // "I am unsure" triggers "If 'Unsure', what best explains uncertainty?"
    if (unsureFollowUp) {
        followUps.push({
            answerIndices: [3],  // "I am unsure" is index 3
            questionId: unsureFollowUp.id
        });
        console.log('  Unsure follow-up: Q' + unsureFollowUp.id + ' - ' + unsureFollowUp.question_text.substring(0, 40));
    }

    if (followUps.length > 0) {
        qChildren.follow_ups = followUps;
    }
}

// Build final JSON
const questionBank = {
    topics: topicsData,
    subtopics: subtopicsData,
    questions: questionsData
};

// Save to file
fs.writeFileSync('question_bank_v2.json', JSON.stringify(questionBank, null, 2));
console.log('\nGenerated question_bank_v2.json with:');
console.log('  Topics:', topicsData.length);
console.log('  Subtopics:', subtopicsData.length);
console.log('  Questions:', questionsData.length);

// Show single_choice questions with follow_ups
console.log('\nSingle choice questions with follow_ups:');
questionsData.filter(q => q.question_type === 'single_choice').forEach(q => {
    console.log(`  Q${q.id}: ${q.question_text.substring(0, 50)}...`);
    if (q.follow_ups) {
        q.follow_ups.forEach(f => {
            console.log(`    -> answerIndices: [${f.answerIndices.join(', ')}] -> Q${f.questionId}`);
        });
    }
});
