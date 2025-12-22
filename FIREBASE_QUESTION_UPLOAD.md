# Manual Firebase Question Bank Upload

## Option 1: Upload via Firebase Console (Easiest)

### Step 1: Open Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your Zawaj project
3. Navigate to **Firestore Database** in the left menu

### Step 2: Create Questions Collection
1. Click "Start collection"
2. Collection ID: `questions`
3. Click "Next"

### Step 3: Add Each Question

For each question in `/Resources/question_bank.json`, create a document:

#### Question 1: Religious Values
- **Document ID**: `q001`
- Fields:
  - `questionText` (string): `How important is it to you that your partner shares your religious beliefs and practices?`
  - `questionType` (string): `multipleChoice`
  - `options` (array):
    - `Extremely important - we must share the same beliefs and level of practice`
    - `Very important - same beliefs, but different practice levels are okay`
    - `Somewhat important - mutual respect is more important than identical beliefs`
    - `Not very important - as long as we respect each other's views`
  - `topic` (string): `Religious values`
  - `followUpPrompt` (string): `What aspects of religious practice would you want to share with your partner?`
  - `isActive` (boolean): `true`
  - `createdAt` (timestamp): Click "auto"

#### Question 2: Family Expectations
- **Document ID**: `q002`
- Fields:
  - `questionText` (string): `What role do you envision your families playing in your married life?`
  - `questionType` (string): `multipleChoice`
  - `options` (array):
    - `Very involved - family gatherings weekly, active in decision-making`
    - `Moderately involved - regular visits but maintain independence`
    - `Occasionally involved - major holidays and events only`
    - `Minimal involvement - we prioritize our own family unit`
  - `topic` (string): `Family expectations`
  - `followUpPrompt` (string): `How would you handle disagreements between your partner and your family?`
  - `isActive` (boolean): `true`
  - `createdAt` (timestamp): Click "auto"

#### Question 3: Personality Compatibility
- **Document ID**: `q003`
- Fields:
  - `questionText` (string): `Which personality trait do you value most in a long-term partner?`
  - `questionType` (string): `multipleChoice`
  - `options` (array):
    - `Emotional intelligence and empathy`
    - `Humor and ability to laugh together`
    - `Honesty and direct communication`
    - `Patience and calmness under pressure`
  - `topic` (string): `Personality and emotional compatibility`
  - `followUpPrompt` (string): `Tell me about a time when this trait was important in a relationship.`
  - `isActive` (boolean): `true`
  - `createdAt` (timestamp): Click "auto"

#### Question 4: Lifestyle and Goals
- **Document ID**: `q004`
- Fields:
  - `questionText` (string): `What does your ideal lifestyle look like 5 years from now?`
  - `questionType` (string): `openEnded`
  - `topic` (string): `Lifestyle and goals`
  - `followUpPrompt` (string): `Describe a typical weekend in your ideal future life.`
  - `isActive` (boolean): `true`
  - `createdAt` (timestamp): Click "auto"

**Note**: No `options` field for open-ended questions

#### Question 5: Finances
- **Document ID**: `q005`
- Fields:
  - `questionText` (string): `How do you think married couples should handle their finances?`
  - `questionType` (string): `multipleChoice`
  - `options` (array):
    - `Completely combined - one joint account for everything`
    - `Mostly combined - joint account for shared expenses, separate for personal`
    - `Mostly separate - split shared expenses, keep income separate`
    - `Flexible approach - whatever works best for both partners`
  - `topic` (string): `Finances and career plans`
  - `followUpPrompt` (string): `How would you approach the conversation if your partner earned significantly more or less than you?`
  - `isActive` (boolean): `true`
  - `createdAt` (timestamp): Click "auto"

#### Question 6: Marriage Roles
- **Document ID**: `q006`
- Fields:
  - `questionText` (string): `What's your view on traditional gender roles in marriage?`
  - `questionType` (string): `multipleChoice`
  - `options` (array):
    - `I prefer traditional roles with clear responsibilities`
    - `I like some traditional aspects but with flexibility`
    - `I prefer equal partnership with shared responsibilities`
    - `Roles should be based on individual strengths, not gender`
  - `topic` (string): `Views on marriage roles`
  - `followUpPrompt` (string): `How would you and your partner decide who does what in your household?`
  - `isActive` (boolean): `true`
  - `createdAt` (timestamp): Click "auto"

#### Question 7: Parenting
- **Document ID**: `q007`
- Fields:
  - `questionText` (string): `When do you envision having children, and how many would you ideally want?`
  - `questionType` (string): `multipleChoice`
  - `options` (array):
    - `Soon after marriage, 3+ children`
    - `Within 2-3 years, 2-3 children`
    - `After 5+ years or career stability, 1-2 children`
    - `Unsure about children or prefer not to have them`
  - `topic` (string): `Parenting views`
  - `followUpPrompt` (string): `What's your parenting philosophy? How would you want to raise children?`
  - `isActive` (boolean): `true`
  - `createdAt` (timestamp): Click "auto"

#### Question 8: Conflict Resolution
- **Document ID**: `q008`
- Fields:
  - `questionText` (string): `When you and your partner disagree, what's your typical approach?`
  - `questionType` (string): `multipleChoice`
  - `options` (array):
    - `Address it immediately - talk through it right away`
    - `Take time to cool down first, then discuss calmly`
    - `Try to understand their perspective before sharing mine`
    - `Seek compromise - focus on finding middle ground`
  - `topic` (string): `Conflict resolution style`
  - `followUpPrompt` (string): `Describe a conflict you've resolved successfully. What made it work?`
  - `isActive` (boolean): `true`
  - `createdAt` (timestamp): Click "auto"

### Step 4: Create Metadata Collection
1. Create a new collection: `questionBankMetadata`
2. Document ID: `current`
3. Fields:
   - `version` (string): `1.0`
   - `totalQuestions` (number): `8`
   - `topics` (array): `Religious values`, `Family expectations`, `Personality and emotional compatibility`, `Lifestyle and goals`, `Finances and career plans`, `Views on marriage roles`, `Parenting views`, `Conflict resolution style`
   - `description` (string): `Initial question bank for Zawaj MVP - one question per relationship topic`
   - `uploadedAt` (timestamp): Click "auto"

---

## Option 2: Import JSON via Firebase CLI (Advanced)

### Prerequisites
```bash
npm install -g firebase-tools
firebase login
```

### Create Import Script
Create a file `upload-questions.js`:

```javascript
const admin = require('firebase-admin');
const fs = require('fs');

// Initialize Firebase Admin
const serviceAccount = require('./path/to/serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Load question bank
const questionBank = JSON.parse(
  fs.readFileSync('./Resources/question_bank.json', 'utf8')
);

async function uploadQuestions() {
  const batch = db.batch();

  // Upload each question
  for (const question of questionBank.questions) {
    const questionRef = db.collection('questions').doc(question.id);

    const questionData = {
      questionText: question.questionText,
      questionType: question.questionType,
      topic: question.topic,
      followUpPrompt: question.followUpPrompt,
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    };

    if (question.options) {
      questionData.options = question.options;
    }

    batch.set(questionRef, questionData);
  }

  // Upload metadata
  const metadataRef = db.collection('questionBankMetadata').doc('current');
  batch.set(metadataRef, {
    version: questionBank.metadata.version,
    totalQuestions: questionBank.metadata.totalQuestions,
    topics: questionBank.metadata.topics,
    description: questionBank.metadata.description,
    uploadedAt: admin.firestore.FieldValue.serverTimestamp()
  });

  await batch.commit();
  console.log('Successfully uploaded', questionBank.questions.length, 'questions!');
}

uploadQuestions()
  .then(() => process.exit(0))
  .catch(error => {
    console.error('Error:', error);
    process.exit(1);
  });
```

### Run Upload
```bash
node upload-questions.js
```

---

## Verify Upload

1. Go to Firestore Database in Firebase Console
2. Check that `questions` collection has 8 documents (q001-q008)
3. Check that `questionBankMetadata` collection has 1 document (current)
4. Verify each question has all required fields

---

## Quick Reference: All Question IDs

- `q001` - Religious values
- `q002` - Family expectations
- `q003` - Personality compatibility
- `q004` - Lifestyle and goals
- `q005` - Finances
- `q006` - Marriage roles
- `q007` - Parenting
- `q008` - Conflict resolution

---

## Next Steps

After upload:
1. Questions are ready to use in the app
2. Use `QuestionBankService.fetchRandomQuestion()` to get questions
3. Implement daily question assignment (Cloud Function recommended)
4. Build question detail screen to display and answer questions

---

## Notes

- Upload these questions **once** only
- To add more questions later, create new documents with IDs q009, q010, etc.
- Update `questionBankMetadata/current` `totalQuestions` when adding more
- Set `isActive: false` to temporarily disable a question
