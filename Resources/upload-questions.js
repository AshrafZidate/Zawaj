const fs = require('fs');
const https = require('https');

// Configuration
const PROJECT_ID = 'zawaj-zawaj';

// Get Firebase access token from CLI config
function getAccessToken() {
    const configPath = `${process.env.HOME}/.config/configstore/firebase-tools.json`;
    try {
        const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
        if (config.tokens && config.tokens.access_token) {
            return config.tokens.access_token;
        }
        throw new Error('No access token found in Firebase CLI config');
    } catch (error) {
        console.error('Error getting access token:', error.message);
        console.error('Please run "firebase login" first');
        process.exit(1);
    }
}

// Make a Firestore REST API request
function firestoreRequest(method, path, data = null) {
    const accessToken = getAccessToken();

    return new Promise((resolve, reject) => {
        const options = {
            hostname: 'firestore.googleapis.com',
            port: 443,
            path: `/v1/projects/${PROJECT_ID}/databases/(default)/documents${path}`,
            method: method,
            headers: {
                'Authorization': `Bearer ${accessToken}`,
                'Content-Type': 'application/json',
            }
        };

        const req = https.request(options, (res) => {
            let body = '';
            res.on('data', chunk => body += chunk);
            res.on('end', () => {
                if (res.statusCode >= 200 && res.statusCode < 300) {
                    resolve(body ? JSON.parse(body) : {});
                } else {
                    reject(new Error(`HTTP ${res.statusCode}: ${body}`));
                }
            });
        });

        req.on('error', reject);

        if (data) {
            req.write(JSON.stringify(data));
        }
        req.end();
    });
}

// Convert a value to Firestore format
function toFirestoreValue(value) {
    if (value === null || value === undefined) {
        return { nullValue: null };
    } else if (typeof value === 'boolean') {
        return { booleanValue: value };
    } else if (typeof value === 'number') {
        if (Number.isInteger(value)) {
            return { integerValue: value.toString() };
        }
        return { doubleValue: value };
    } else if (typeof value === 'string') {
        return { stringValue: value };
    } else if (Array.isArray(value)) {
        return { arrayValue: { values: value.map(toFirestoreValue) } };
    } else if (typeof value === 'object') {
        const fields = {};
        for (const [k, v] of Object.entries(value)) {
            fields[k] = toFirestoreValue(v);
        }
        return { mapValue: { fields } };
    }
    return { stringValue: String(value) };
}

// Create a Firestore document
function createDocument(collection, docId, data) {
    const fields = {};
    const fieldPaths = [];

    for (const [key, value] of Object.entries(data)) {
        fields[key] = toFirestoreValue(value);
        fieldPaths.push(key);
    }

    // Add created_at timestamp
    fields['created_at'] = { timestampValue: new Date().toISOString() };
    fieldPaths.push('created_at');

    // Build update mask query string
    const updateMask = fieldPaths.map(p => `updateMask.fieldPaths=${p}`).join('&');

    return firestoreRequest('PATCH', `/${collection}/${docId}?${updateMask}`, { fields });
}

// Load and upload question bank
async function uploadQuestionBank() {
    console.log('Loading question bank...');
    const data = JSON.parse(fs.readFileSync('question_bank_v2.json', 'utf8'));

    console.log(`Found ${data.topics.length} topics, ${data.subtopics.length} subtopics, ${data.questions.length} questions`);

    // Upload topics
    console.log('\nUploading topics...');
    for (const topic of data.topics) {
        await createDocument('topics', topic.id.toString(), topic);
        console.log(`  Topic ${topic.id}: ${topic.name}`);
    }

    // Upload subtopics
    console.log('\nUploading subtopics...');
    for (const subtopic of data.subtopics) {
        await createDocument('subtopics', subtopic.id.toString(), subtopic);
        if (subtopic.id % 10 === 0) {
            console.log(`  Subtopic ${subtopic.id}...`);
        }
    }
    console.log(`  Uploaded ${data.subtopics.length} subtopics`);

    // Upload questions
    console.log('\nUploading questions...');
    for (const question of data.questions) {
        await createDocument('questions', question.id.toString(), question);
        if (question.id % 50 === 0) {
            console.log(`  Question ${question.id}...`);
        }
    }
    console.log(`  Uploaded ${data.questions.length} questions`);

    console.log('\nDone!');
}

uploadQuestionBank().catch(console.error);
