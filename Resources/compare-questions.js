const fs = require('fs');

// Load database questions
const data = JSON.parse(fs.readFileSync('question_bank_v2.json', 'utf8'));
const dbQuestions = data.questions.map(q => q.question_text.toLowerCase().trim());

// Load docx questions
const docxContent = fs.readFileSync('/tmp/docx_questions.txt', 'utf8');
const docxQuestions = docxContent
    .split('\n')
    .filter(line => line.includes('?'))
    .map(q => q.toLowerCase().trim());

console.log(`Database has ${dbQuestions.length} questions`);
console.log(`Word doc has ${docxQuestions.length} questions\n`);

// Find questions in docx but not in database
const missing = [];
docxQuestions.forEach(docQ => {
    // Check if any DB question matches (fuzzy match - first 40 chars)
    const docPrefix = docQ.substring(0, 40);
    const found = dbQuestions.some(dbQ => dbQ.substring(0, 40) === docPrefix);
    if (!found) {
        missing.push(docQ);
    }
});

console.log(`Questions in Word doc but NOT in database: ${missing.length}`);
if (missing.length > 0) {
    console.log('\nMissing questions:');
    missing.forEach((q, i) => console.log(`${i + 1}. ${q}`));
}

// Find questions in database but not in docx
const extra = [];
dbQuestions.forEach(dbQ => {
    const dbPrefix = dbQ.substring(0, 40);
    const found = docxQuestions.some(docQ => docQ.substring(0, 40) === dbPrefix);
    if (!found) {
        extra.push(dbQ);
    }
});

console.log(`\n\nQuestions in database but NOT in Word doc: ${extra.length}`);
if (extra.length > 0) {
    console.log('\nExtra questions:');
    extra.forEach((q, i) => console.log(`${i + 1}. ${q}`));
}
