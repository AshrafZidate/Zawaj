const fs = require('fs');

const docxContent = fs.readFileSync('/tmp/docx_questions.txt', 'utf8');
const lines = docxContent.split('\n').map(l => l.trim()).filter(l => l);

// Topic headers - normalize apostrophes for matching
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
    "UNDERSTANDING THE WOMAN'S MENSTRUAL CYCLE": "Understanding the Woman's Menstrual Cycle",
    "UNDERSTANDING THE WOMAN'S MENSTRUAL CYCLE": "Understanding the Woman's Menstrual Cycle"  // Handle fancy apostrophe
};

// Normalize apostrophes for matching (handle U+2019 right single quotation mark)
function normalizeApostrophes(str) {
    return str.replace(/[\u2018\u2019'']/g, "'");
}

// Subtopic patterns - lines that are subtitles (short, no ?, capitalized or title case)
function isSubtopic(line, prevLine) {
    if (line.includes('?')) return false;
    if (line.length > 60) return false;
    // Check if previous line was a question or empty or topic
    const words = line.split(' ');
    // Subtopics usually have 2-6 words, all capitalized first letters
    if (words.length >= 2 && words.length <= 8) {
        const allCapitalized = words.every(w => w.length === 0 || w[0] === w[0].toUpperCase() || !isNaN(w[0]));
        if (allCapitalized && !line.includes('(Select all)') && !line.includes('(Rank')) {
            return true;
        }
    }
    return false;
}

// Parse the document
let currentTopic = null;
let currentSubtopic = null;
let currentQuestion = null;
let currentOptions = [];
let questions = [];
let topics = {};
let subtopics = {};
let subtopicId = 1;
let questionId = 1;
let currentGender = null; // For menstrual cycle section

for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const upperLine = line.toUpperCase();

    // Check for topic header (normalize apostrophes for matching)
    let foundTopic = null;
    const normalizedUpperLine = normalizeApostrophes(upperLine);
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

        if (!topics[currentTopic]) {
            topics[currentTopic] = { name: currentTopic, subtopics: [] };
        }
        continue;
    }

    // Check for gender-specific sections in menstrual cycle (handle fancy apostrophes)
    if (currentTopic === "Understanding the Woman's Menstrual Cycle") {
        const normalizedLine = normalizeApostrophes(line);
        if (normalizedLine.includes("Men's Version") || normalizedLine.includes("Husband Perspective")) {
            currentGender = 'male';
            continue;
        }
        if (normalizedLine.includes("Women's Version") || normalizedLine.includes("Wife Perspective")) {
            currentGender = 'female';
            continue;
        }
    }

    // Check for subtopic
    if (currentTopic && isSubtopic(line, i > 0 ? lines[i-1] : '')) {
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
        currentSubtopic = line;
        currentQuestion = null;
        currentOptions = [];

        if (!subtopics[currentSubtopic]) {
            subtopics[currentSubtopic] = { name: currentSubtopic, topic: currentTopic };
            topics[currentTopic].subtopics.push(currentSubtopic);
        }
        continue;
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
        continue;
    }

    // Must be an option
    if (currentQuestion && line.length > 0) {
        // Skip if it looks like a note or instruction
        if (!line.startsWith('Note:') && !line.startsWith('If ') && line.length < 100) {
            currentOptions.push(line);
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

// Determine question type based on rules:
// - singleChoice: Only for questions that have follow-ups (questions 2, 4, 153)
// - multiChoice: Questions with "(Select all)" or multiple selections allowed
// - openEnded: Everything else (pick one from options OR free text based on user pref)

const followUpParents = [
    "How do you feel about where you are religiously at this stage of life?",
    "How often do you pray the five daily prayers?",
    "Do you want children?"
];

questions.forEach((q, idx) => {
    const isMultiSelect = q.question.includes('(Select all)') || q.question.includes('(Rank');
    const isFollowUpParent = followUpParents.some(fp =>
        q.question.toLowerCase().includes(fp.toLowerCase().substring(0, 30))
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
console.log(`Total topics: ${Object.keys(topics).length}`);
console.log(`Total subtopics: ${Object.keys(subtopics).length}`);

console.log('\n=== QUESTIONS BY TOPIC ===\n');
const topicCounts = {};
questions.forEach(q => {
    if (!topicCounts[q.topic]) topicCounts[q.topic] = 0;
    topicCounts[q.topic]++;
});
Object.entries(topicCounts).forEach(([topic, count]) => {
    console.log(`${topic}: ${count}`);
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

console.log('\n=== SINGLE_CHOICE QUESTIONS (should only be follow-up parents) ===\n');
questions.filter(q => q.type === 'single_choice').forEach((q, i) => {
    console.log(`${i+1}. ${q.question}`);
});

console.log('\n=== SAMPLE MULTI_CHOICE QUESTIONS ===\n');
questions.filter(q => q.type === 'multi_choice').slice(0, 10).forEach((q, i) => {
    console.log(`${i+1}. ${q.question}`);
});

// Save parsed data
fs.writeFileSync('/tmp/parsed_questions.json', JSON.stringify(questions, null, 2));
console.log('\n\nParsed questions saved to /tmp/parsed_questions.json');
