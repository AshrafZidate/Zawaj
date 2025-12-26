const fs = require('fs');
const https = require('https');

const PROJECT_ID = 'zawaj-zawaj';

function getAccessToken() {
    const configPath = `${process.env.HOME}/.config/configstore/firebase-tools.json`;
    const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    return config.tokens.access_token;
}

function firestoreRequest(path) {
    const accessToken = getAccessToken();

    return new Promise((resolve, reject) => {
        const options = {
            hostname: 'firestore.googleapis.com',
            port: 443,
            path: `/v1/projects/${PROJECT_ID}/databases/(default)/documents${path}`,
            method: 'GET',
            headers: {
                'Authorization': `Bearer ${accessToken}`,
            }
        };

        const req = https.request(options, (res) => {
            let body = '';
            res.on('data', chunk => body += chunk);
            res.on('end', () => {
                if (res.statusCode >= 200 && res.statusCode < 300) {
                    resolve(JSON.parse(body));
                } else {
                    reject(new Error(`HTTP ${res.statusCode}: ${body}`));
                }
            });
        });

        req.on('error', reject);
        req.end();
    });
}

async function verify() {
    console.log('=== FIREBASE VERIFICATION ===\n');

    // Count topics
    const topicsRes = await firestoreRequest('/topics?pageSize=100');
    const topicCount = topicsRes.documents ? topicsRes.documents.length : 0;
    console.log('Topics in Firebase:', topicCount);

    // Count subtopics
    const subtopicsRes = await firestoreRequest('/subtopics?pageSize=100');
    const subtopicCount = subtopicsRes.documents ? subtopicsRes.documents.length : 0;
    console.log('Subtopics in Firebase:', subtopicCount);

    // Count questions (need to paginate)
    let questionCount = 0;
    let pageToken = null;
    do {
        const url = pageToken
            ? `/questions?pageSize=100&pageToken=${pageToken}`
            : '/questions?pageSize=100';
        const questionsRes = await firestoreRequest(url);
        if (questionsRes.documents) {
            questionCount += questionsRes.documents.length;
        }
        pageToken = questionsRes.nextPageToken;
    } while (pageToken);

    console.log('Questions in Firebase:', questionCount);

    // Verify follow_ups on specific questions
    console.log('\n=== FOLLOW-UPS VERIFICATION ===\n');

    const q2 = await firestoreRequest('/questions/2');
    const q4 = await firestoreRequest('/questions/4');
    const q152 = await firestoreRequest('/questions/152');

    console.log('Q2 (religious feeling):');
    if (q2.fields && q2.fields.follow_ups) {
        console.log('  Has follow_ups:', JSON.stringify(q2.fields.follow_ups, null, 2).substring(0, 200));
    } else {
        console.log('  NO follow_ups found');
    }

    console.log('\nQ4 (prayer frequency):');
    if (q4.fields && q4.fields.follow_ups) {
        console.log('  Has follow_ups:', JSON.stringify(q4.fields.follow_ups, null, 2).substring(0, 200));
    } else {
        console.log('  NO follow_ups found');
    }

    console.log('\nQ152 (children):');
    if (q152.fields && q152.fields.follow_ups) {
        console.log('  Has follow_ups:', JSON.stringify(q152.fields.follow_ups, null, 2).substring(0, 300));
    } else {
        console.log('  NO follow_ups found');
    }

    console.log('\n=== VERIFICATION COMPLETE ===');
}

verify().catch(console.error);
