#!/usr/bin/env node

const { execSync, spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const https = require('https');

// Read the question bank JSON
const questionBankPath = path.join(__dirname, 'Resources', 'question_bank_v2.json');
const questionBank = JSON.parse(fs.readFileSync(questionBankPath, 'utf8'));

// Get Firebase project ID
function getProjectId() {
  try {
    const firebaserc = JSON.parse(fs.readFileSync(path.join(__dirname, '.firebaserc'), 'utf8'));
    return firebaserc.projects?.default || 'zawaj-zawaj';
  } catch {
    return 'zawaj-zawaj';
  }
}

// Get access token using Firebase CLI
function getAccessToken() {
  try {
    // Try getting token from Firebase CLI
    const result = spawnSync('npx', ['firebase-tools', 'login:add', '--no-localhost'], {
      encoding: 'utf8',
      stdio: 'pipe',
      timeout: 5000
    });

    // Try to get the token from the config file
    const homeDir = process.env.HOME || process.env.USERPROFILE;
    const configPath = path.join(homeDir, '.config', 'configstore', 'firebase-tools.json');

    if (fs.existsSync(configPath)) {
      const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
      const tokens = config.tokens;
      if (tokens && tokens.access_token) {
        return tokens.access_token;
      }
      // Try refresh token approach
      if (tokens && tokens.refresh_token) {
        console.log('Found refresh token, attempting to get access token...');
        return refreshAccessToken(tokens.refresh_token);
      }
    }

    throw new Error('No Firebase authentication found');
  } catch (error) {
    console.error('Failed to get access token.');
    console.error('Please run: firebase login');
    console.error('Error:', error.message);
    process.exit(1);
  }
}

// Refresh access token using refresh token
function refreshAccessToken(refreshToken) {
  // This would require making a POST request to Google's OAuth endpoint
  // For simplicity, we'll use the firebase-admin SDK approach instead
  throw new Error('Please use firebase-admin SDK or run: firebase login');
}

// Create a Firestore document via REST API
function createDocument(projectId, accessToken, collection, docId, data) {
  return new Promise((resolve, reject) => {
    const fields = {};

    for (const [key, value] of Object.entries(data)) {
      if (value === null) {
        fields[key] = { nullValue: null };
      } else if (typeof value === 'string') {
        fields[key] = { stringValue: value };
      } else if (typeof value === 'number') {
        fields[key] = Number.isInteger(value) ? { integerValue: value.toString() } : { doubleValue: value };
      } else if (typeof value === 'boolean') {
        fields[key] = { booleanValue: value };
      } else if (Array.isArray(value)) {
        fields[key] = {
          arrayValue: {
            values: value.map(v => {
              if (typeof v === 'string') return { stringValue: v };
              if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: v.toString() } : { doubleValue: v };
              return { stringValue: String(v) };
            })
          }
        };
      } else if (typeof value === 'object') {
        // Nested object (like branch_condition)
        const mapFields = {};
        for (const [k, v] of Object.entries(value)) {
          if (typeof v === 'string') {
            mapFields[k] = { stringValue: v };
          } else if (typeof v === 'number') {
            mapFields[k] = Number.isInteger(v) ? { integerValue: v.toString() } : { doubleValue: v };
          } else if (Array.isArray(v)) {
            mapFields[k] = {
              arrayValue: {
                values: v.map(item => {
                  if (typeof item === 'string') return { stringValue: item };
                  if (typeof item === 'number') return Number.isInteger(item) ? { integerValue: item.toString() } : { doubleValue: item };
                  return { stringValue: String(item) };
                })
              }
            };
          }
        }
        fields[key] = { mapValue: { fields: mapFields } };
      }
    }

    const body = JSON.stringify({ fields });

    const options = {
      hostname: 'firestore.googleapis.com',
      port: 443,
      path: `/v1/projects/${projectId}/databases/(default)/documents/${collection}/${docId}`,
      method: 'PATCH',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body)
      }
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(true);
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data}`));
        }
      });
    });

    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

// Batch upload with progress
async function uploadWithProgress(projectId, accessToken, collection, items, formatFn) {
  let success = 0;
  let failed = 0;

  for (let i = 0; i < items.length; i++) {
    const item = items[i];
    const data = formatFn(item);
    const docId = item.id.toString();

    process.stdout.write(`\r  [${i + 1}/${items.length}] ${collection}/${docId}...`);

    try {
      await createDocument(projectId, accessToken, collection, docId, data);
      success++;
    } catch (error) {
      failed++;
      console.error(`\n    Error: ${error.message}`);
    }
  }

  console.log(`\n  ✓ ${success} uploaded, ${failed} failed`);
  return { success, failed };
}

async function main() {
  console.log('Question Bank Upload Script\n');
  console.log('='.repeat(50));

  const projectId = getProjectId();
  console.log(`Project: ${projectId}`);

  console.log('Getting access token...');
  const accessToken = getAccessToken();
  console.log('✓ Authenticated\n');

  const timestamp = new Date().toISOString();

  // Upload topics
  console.log(`Uploading ${questionBank.topics.length} topics...`);
  await uploadWithProgress(projectId, accessToken, 'topics', questionBank.topics, (topic) => ({
    id: topic.id,
    name: topic.name,
    order: topic.order,
    is_rankable: topic.is_rankable,
    created_at: timestamp,
    archived_at: null
  }));

  // Upload subtopics
  console.log(`\nUploading ${questionBank.subtopics.length} subtopics...`);
  await uploadWithProgress(projectId, accessToken, 'subtopics', questionBank.subtopics, (subtopic) => ({
    id: subtopic.id,
    topic_id: subtopic.topic_id,
    name: subtopic.name,
    order: subtopic.order,
    created_at: timestamp,
    archived_at: null
  }));

  // Upload questions
  console.log(`\nUploading ${questionBank.questions.length} questions...`);
  await uploadWithProgress(projectId, accessToken, 'questions', questionBank.questions, (question) => ({
    id: question.id,
    subtopic_id: question.subtopic_id,
    question_text: question.question_text,
    question_type: question.question_type,
    options: question.options,
    order: question.order,
    gender: question.gender,
    branch_condition: question.branch_condition,
    created_at: timestamp,
    archived_at: null
  }));

  console.log('\n' + '='.repeat(50));
  console.log('Upload complete!');
  console.log(`Topics: ${questionBank.topics.length}`);
  console.log(`Subtopics: ${questionBank.subtopics.length}`);
  console.log(`Questions: ${questionBank.questions.length}`);
  console.log('='.repeat(50));
}

main().catch(console.error);
