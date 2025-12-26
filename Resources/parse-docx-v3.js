const fs = require('fs');

const docxContent = fs.readFileSync('/tmp/docx_questions.txt', 'utf8');
const lines = docxContent.split('\n').map(l => l.trim()).filter(l => l);

// Topic-subtopic mapping from database (preserves correct associations)
const topicSubtopics = {
    "Religious Values": [
        "Core Relationship With Islam",
        "Practice and Daily Worship",
        "Growth, Intentions, and Direction",
        "Halal, Haram, and Boundaries",
        "Islamic Knowledge and Learning",
        "Community, Environment, and Identity",
        "Marriage, Deen, and Expectations",
        "Differences and Deal-Breakers"
    ],
    "Personality and Emotional Compatibility": [
        "Emotional Needs and Connection",
        "Stress, Pressure, and Regulation",
        "Communication Style",
        "Affection and Reassurance",
        "Temperament and Personality Fit",
        "Conflict Triggers and Repair",
        "Emotional Maturity and Trust"
    ],
    "Lifestyle and Long-Term Goals": [
        "Day-to-Day Lifestyle Alignment",
        "Social Life and Balance",
        "Work, Ambition, and Time Priorities",
        "Financial Lifestyle",
        "Financial Lifestyle (Living Style)",
        "Location, Living Arrangements, and Mobility",
        "Pace of Life and Energy Levels",
        "Planning vs Flexibility",
        "Travel, Downtime, and Enjoyment",
        "Seasons of Life and Change",
        "Expectations of Marriage and the Future",
        "Deal-Breakers and Flexibility"
    ],
    "Views on Marriage Roles and Responsibilities": [
        "Core View of Marriage Roles",
        "Leadership, Authority, and Decision-Making",
        "Domestic Responsibilities",
        "Independence and Personal Space",
        "Obedience, Compromise, and Flexibility",
        "Gender Expectations and Cultural Influence",
        "Respect, Boundaries, and Mutual Regard",
        "Children and Role Modelling",
        "Deal-Breakers and Clarity"
    ],
    "Family Expectations, In-Laws, and Boundaries": [
        "Importance of Family",
        "Parental Influence and Authority",
        "Living Arrangements and Proximity",
        "In-Law Relationships",
        "Boundaries and Privacy",
        "Conflict Involving Family",
        "Cultural Expectations and Pressure",
        "Siblings and Wider Family",
        "Loyalty, Prioritisation, and Unity",
        "Scenarios and Reality Checks",
        "Deal-Breakers and Clarity"
    ],
    "Parenting, Children, and Family Building": [
        "Desire for Children",
        "Parenting Philosophy and Values",
        "Discipline and Boundaries",
        "Roles, Sacrifices, and Responsibility",
        "Emotional Readiness and Patience",
        "Health, Fertility, and Reality Scenarios",
        "Environment and Upbringing",
        "Boundaries and External Influence",
        "Long-Term Vision and Deal-Breakers"
    ],
    "Conflict Resolution, Disagreements, and Repair": [
        "Core Conflict Orientation",
        "Emotional Regulation During Conflict",
        "Timing, Space, and Processing",
        "Communication Under Disagreement",
        "Apologies, Accountability, and Repair",
        "Patterns, Triggers, and Escalation",
        "Silent Treatment, Avoidance, and Pausing",
        "Seeking Help and Support",
        "Learning From Conflict",
        "Scenarios and Safety"
    ],
    "Finances, Provision, and Money Attitudes": [
        "Core Money Mindset",
        "Provision and Responsibility",
        "Spending, Saving, Lifestyle",
        "Shared vs Separate Finances",
        "Debt, Risk, and Responsibility",
        "Financial Stress and Conflict",
        "Work, Sacrifice, Trade-Offs",
        "Generosity, Zakat, Giving",
        "Future Planning and Deal-Breakers"
    ],
    "Health, Well-being, and Personal Growth": [
        "Overall Health Orientation",
        "Physical Health Habits",
        "Mental and Emotional Well-being",
        "Support and Expectations in Marriage",
        "Boundaries, Capacity, Burnout",
        "Healing, Past Experiences, Growth",
        "Seeking Help and Support Systems",
        "Growth Mindset in Marriage",
        "Habits, Discipline, Consistency",
        "Difficult Seasons and Sustainability"
    ],
    "Understanding the Woman's Menstrual Cycle": [
        "Men's Version (Husband Perspective)",
        "Women's Version (Wife Perspective)"
    ]
};

// Topic headers
const topicHeaders = {
    'RELIGIOUS VALUES': 'Religious Values',
    'PERSONALITY AND EMOTIONAL COMPATIBILITY': 'Personality and Emotional Compatibility',
    'LIFESTYLE AND LONG-TERM GOALS': 'Lifestyle and Long-Term Goals',
    'VIEWS ON MARRIAGE ROLES AND RESPONSIBILITIES': 'Views on Marriage Roles and Responsibilities',
    'FAMILY EXPECTATIONS, IN-LAWS, AND BOUNDARIES': 'Family Expectations, In-Laws, and Boundaries',
    'PARENTING, CHILDREN, AND FAMILY BUILDING': 'Parenting, Children, and Family Building',
    'CONFLICT RESOLUTION, DISAGREEMENTS, AND REPAIR': 'Conflict Resolution, Disagreements, and Repair',
    'FINANCES, PROVISION, AND MONEY ATTITUDES': 'Finances, Provision, and Money Attitudes',
    'HEALTH, WELL-BEING, AND PERSONAL GROWTH': 'Health, Well-being, and Personal Growth',
    "UNDERSTANDING THE WOMAN'S MENSTRUAL CYCLE": "Understanding the Woman's Menstrual Cycle"
};

function normalizeApostrophes(str) {
    return str.replace(/[\u2018\u2019'']/g, "'");
}

function normalize(str) {
    return normalizeApostrophes(str).toLowerCase().trim();
}

// Check if line matches a subtopic for the current topic
function matchSubtopic(line, topic) {
    if (!topic || !topicSubtopics[topic]) return null;
    const normalizedLine = normalize(line);

    for (const subtopic of topicSubtopics[topic]) {
        if (normalize(subtopic) === normalizedLine) {
            return subtopic;
        }
    }
    return null;
}

// Parse the document
let currentTopic = null;
let currentSubtopic = null;
let currentQuestion = null;
let currentOptions = [];
let questions = [];
let subtopicsFound = {};
let currentGender = null;
let lastLineWasOption = false;

for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const upperLine = line.toUpperCase();
    const normalizedUpperLine = normalizeApostrophes(upperLine);

    // Check for topic header
    let foundTopic = null;
    for (const [header, name] of Object.entries(topicHeaders)) {
        const normalizedHeader = normalizeApostrophes(header);
        if (normalizedUpperLine === normalizedHeader || normalizedUpperLine.includes(normalizedHeader)) {
            foundTopic = name;
            break;
        }
    }

    if (foundTopic) {
        // Save previous question if exists
        if (currentQuestion && currentOptions.length > 0) {
            questions.push({
                question: currentQuestion,
                options: [...currentOptions],
                topic: currentTopic,
                subtopic: currentSubtopic,
                gender: currentGender
            });
        }
        currentTopic = foundTopic;
        currentSubtopic = null;
        currentQuestion = null;
        currentOptions = [];
        currentGender = null;
        lastLineWasOption = false;

        if (!subtopicsFound[currentTopic]) {
            subtopicsFound[currentTopic] = [];
        }
        continue;
    }

    // Check for gender-specific sections in menstrual cycle
    if (currentTopic === "Understanding the Woman's Menstrual Cycle") {
        const normalizedLine = normalizeApostrophes(line);
        if (normalizedLine.includes("Men's Version") || line.includes("Husband Perspective")) {
            if (currentQuestion && currentOptions.length > 0) {
                questions.push({
                    question: currentQuestion,
                    options: [...currentOptions],
                    topic: currentTopic,
                    subtopic: currentSubtopic,
                    gender: currentGender
                });
            }
            currentGender = 'male';
            currentSubtopic = "Men's Version (Husband Perspective)";
            if (!subtopicsFound[currentTopic].includes(currentSubtopic)) {
                subtopicsFound[currentTopic].push(currentSubtopic);
            }
            currentQuestion = null;
            currentOptions = [];
            lastLineWasOption = false;
            continue;
        }
        if (normalizedLine.includes("Women's Version") || line.includes("Wife Perspective")) {
            if (currentQuestion && currentOptions.length > 0) {
                questions.push({
                    question: currentQuestion,
                    options: [...currentOptions],
                    topic: currentTopic,
                    subtopic: currentSubtopic,
                    gender: currentGender
                });
            }
            currentGender = 'female';
            currentSubtopic = "Women's Version (Wife Perspective)";
            if (!subtopicsFound[currentTopic].includes(currentSubtopic)) {
                subtopicsFound[currentTopic].push(currentSubtopic);
            }
            currentQuestion = null;
            currentOptions = [];
            lastLineWasOption = false;
            continue;
        }
    }

    // Check if this line is a subtopic (only check if NOT currently collecting options)
    // A subtopic line should not contain '?' and should match our known subtopics
    if (currentTopic && !line.includes('?')) {
        const matchedSubtopic = matchSubtopic(line, currentTopic);
        if (matchedSubtopic) {
            // Save previous question if exists
            if (currentQuestion && currentOptions.length > 0) {
                questions.push({
                    question: currentQuestion,
                    options: [...currentOptions],
                    topic: currentTopic,
                    subtopic: currentSubtopic,
                    gender: currentGender
                });
            }
            currentSubtopic = matchedSubtopic;
            if (!subtopicsFound[currentTopic].includes(currentSubtopic)) {
                subtopicsFound[currentTopic].push(currentSubtopic);
            }
            currentQuestion = null;
            currentOptions = [];
            lastLineWasOption = false;
            continue;
        }
    }

    // Check for question (ends with ?)
    if (line.includes('?')) {
        // Save previous question if exists
        if (currentQuestion && currentOptions.length > 0) {
            questions.push({
                question: currentQuestion,
                options: [...currentOptions],
                topic: currentTopic,
                subtopic: currentSubtopic,
                gender: currentGender
            });
        }
        currentQuestion = line;
        currentOptions = [];
        lastLineWasOption = false;
        continue;
    }

    // Must be an option
    if (currentQuestion && line.length > 0) {
        // Skip if it looks like a note or instruction
        if (!line.startsWith('Note:') && !line.startsWith('If ') && line.length < 150) {
            currentOptions.push(line);
            lastLineWasOption = true;
        }
    }
}

// Save last question
if (currentQuestion && currentOptions.length > 0) {
    questions.push({
        question: currentQuestion,
        options: [...currentOptions],
        topic: currentTopic,
        subtopic: currentSubtopic,
        gender: currentGender
    });
}

// Determine question type
const followUpParents = [
    "How do you feel about where you are religiously at this stage of life?",
    "How often do you pray the five daily prayers?",
    "Do you want children?"
];

questions.forEach((q, idx) => {
    const isMultiSelect = q.question.includes('(Select all)') || q.question.includes('(Rank');
    const normalizedQuestion = normalize(q.question);
    const isFollowUpParent = followUpParents.some(fp =>
        normalizedQuestion.includes(normalize(fp).substring(0, 30))
    );

    if (isFollowUpParent) {
        q.type = 'single_choice';
    } else if (isMultiSelect) {
        q.type = 'multi_choice';
    } else {
        q.type = 'open_ended';
    }
});

// Print summary
console.log('=== PARSING SUMMARY ===\n');
console.log(`Total questions found: ${questions.length}`);
console.log(`Total topics: ${Object.keys(subtopicsFound).length}`);
const totalSubtopics = Object.values(subtopicsFound).reduce((sum, arr) => sum + arr.length, 0);
console.log(`Total subtopics: ${totalSubtopics}`);

console.log('\n=== QUESTIONS BY TOPIC ===\n');
const topicCounts = {};
questions.forEach(q => {
    if (!topicCounts[q.topic]) topicCounts[q.topic] = 0;
    topicCounts[q.topic]++;
});
Object.entries(topicCounts).forEach(([topic, count]) => {
    console.log(`${topic}: ${count}`);
});

console.log('\n=== SUBTOPICS BY TOPIC ===\n');
Object.entries(subtopicsFound).forEach(([topic, subs]) => {
    console.log(`${topic} (${subs.length} subtopics):`);
    subs.forEach(s => console.log(`  - ${s}`));
});

console.log('\n=== QUESTION TYPES ===\n');
const typeCounts = { single_choice: 0, multi_choice: 0, open_ended: 0 };
questions.forEach(q => typeCounts[q.type]++);
console.log(`single_choice: ${typeCounts.single_choice}`);
console.log(`multi_choice: ${typeCounts.multi_choice}`);
console.log(`open_ended: ${typeCounts.open_ended}`);

console.log('\n=== GENDER-SPECIFIC QUESTIONS ===\n');
const genderCounts = { male: 0, female: 0, none: 0 };
questions.forEach(q => {
    if (q.gender === 'male') genderCounts.male++;
    else if (q.gender === 'female') genderCounts.female++;
    else genderCounts.none++;
});
console.log(`Male only: ${genderCounts.male}`);
console.log(`Female only: ${genderCounts.female}`);
console.log(`Both genders: ${genderCounts.none}`);

console.log('\n=== SINGLE_CHOICE QUESTIONS (follow-up parents) ===\n');
questions.filter(q => q.type === 'single_choice').forEach((q, i) => {
    console.log(`${i+1}. ${q.question}`);
});

// Check for questions without subtopics
const noSubtopic = questions.filter(q => !q.subtopic);
if (noSubtopic.length > 0) {
    console.log(`\n=== QUESTIONS WITHOUT SUBTOPIC: ${noSubtopic.length} ===\n`);
    noSubtopic.slice(0, 10).forEach((q, i) => {
        console.log(`${i+1}. [${q.topic}] ${q.question.substring(0, 60)}...`);
    });
}

// Save parsed data
fs.writeFileSync('/tmp/parsed_questions_v3.json', JSON.stringify(questions, null, 2));
console.log('\n\nParsed questions saved to /tmp/parsed_questions_v3.json');
