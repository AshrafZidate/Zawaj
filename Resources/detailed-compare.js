const fs = require('fs');

// Load database questions
const data = JSON.parse(fs.readFileSync('question_bank_v2.json', 'utf8'));

// Get DB topics and their question counts
const dbTopics = {};
data.questions.forEach(q => {
    const subtopic = data.subtopics.find(s => s.id === q.subtopic_id);
    const topic = data.topics.find(t => t.id === subtopic?.topic_id);
    const topicName = topic?.name || 'Unknown';
    if (!dbTopics[topicName]) dbTopics[topicName] = { questions: [], subtopics: new Set() };
    dbTopics[topicName].questions.push(q.question_text);
    dbTopics[topicName].subtopics.add(subtopic?.name);
});

// Load docx content and extract structure
const docxContent = fs.readFileSync('/tmp/docx_questions.txt', 'utf8');
const lines = docxContent.split('\n').map(l => l.trim()).filter(l => l);

// Parse the docx to find topics and questions
let currentTopic = '';
const docTopics = {};
const topicHeaders = [
    'RELIGIOUS VALUES',
    'PERSONALITY AND EMOTIONAL COMPATIBILITY',
    'LIFESTYLE AND LONG-TERM GOALS',
    'VIEWS ON MARRIAGE ROLES AND RESPONSIBILITIES',
    'FAMILY EXPECTATIONS, IN-LAWS, AND BOUNDARIES',
    'PARENTING, CHILDREN, AND FAMILY BUILDING',
    'CONFLICT RESOLUTION, DISAGREEMENTS, AND REPAIR',
    'FINANCES, PROVISION, AND MONEY ATTITUDES',
    'HEALTH, WELL-BEING, AND PERSONAL GROWTH',
    "UNDERSTANDING THE WOMAN'S MENSTRUAL CYCLE"
];

lines.forEach(line => {
    // Check if this is a topic header
    const matchedTopic = topicHeaders.find(t => line.toUpperCase().includes(t));
    if (matchedTopic) {
        currentTopic = matchedTopic;
        if (!docTopics[currentTopic]) docTopics[currentTopic] = [];
        return;
    }

    // Check if this is a question (ends with ?)
    if (line.includes('?') && currentTopic) {
        docTopics[currentTopic].push(line);
    }
});

console.log('=== COMPARISON BY TOPIC ===\n');

// Map DB topic names to doc topic names
const topicMapping = {
    'Religious Values': 'RELIGIOUS VALUES',
    'Personality and Emotional Compatibility': 'PERSONALITY AND EMOTIONAL COMPATIBILITY',
    'Lifestyle and Long-Term Goals': 'LIFESTYLE AND LONG-TERM GOALS',
    'Views on Marriage Roles and Responsibilities': 'VIEWS ON MARRIAGE ROLES AND RESPONSIBILITIES',
    'Family Expectations, In-Laws, and Boundaries': 'FAMILY EXPECTATIONS, IN-LAWS, AND BOUNDARIES',
    'Parenting, Children, and Family Building': 'PARENTING, CHILDREN, AND FAMILY BUILDING',
    'Conflict Resolution, Disagreements, and Repair': 'CONFLICT RESOLUTION, DISAGREEMENTS, AND REPAIR',
    'Finances, Provision, and Money Attitudes': 'FINANCES, PROVISION, AND MONEY ATTITUDES',
    'Health, Well-being, and Personal Growth': 'HEALTH, WELL-BEING, AND PERSONAL GROWTH',
    "Understanding the Woman's Menstrual Cycle": "UNDERSTANDING THE WOMAN'S MENSTRUAL CYCLE"
};

Object.entries(topicMapping).forEach(([dbName, docName]) => {
    const dbCount = dbTopics[dbName]?.questions.length || 0;
    const docCount = docTopics[docName]?.length || 0;
    const diff = docCount - dbCount;
    const status = diff === 0 ? '✓' : diff > 0 ? `MISSING ${diff}` : `EXTRA ${-diff}`;
    console.log(`${dbName}:`);
    console.log(`  Database: ${dbCount}, Word Doc: ${docCount} ${status}`);
});

console.log('\n\n=== DETAILED QUESTION COMPARISON FOR FIRST TOPIC ===\n');

const firstDbTopic = 'Religious Values';
const firstDocTopic = 'RELIGIOUS VALUES';

console.log('Database questions:');
dbTopics[firstDbTopic]?.questions.slice(0, 10).forEach((q, i) => console.log(`  ${i+1}. ${q}`));

console.log('\nWord doc questions:');
docTopics[firstDocTopic]?.slice(0, 10).forEach((q, i) => console.log(`  ${i+1}. ${q}`));
