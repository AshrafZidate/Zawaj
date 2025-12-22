# Question Bank Setup

## Overview
This directory contains the initial question bank for Zawaj, with one carefully crafted question for each of the 8 relationship topics.

## Topics Covered
1. **Religious values** - Importance of shared beliefs and practices
2. **Family expectations** - Role of families in married life
3. **Personality and emotional compatibility** - Key traits in a partner
4. **Lifestyle and goals** - Vision for future life together
5. **Finances and career plans** - Financial management approach
6. **Views on marriage roles** - Perspectives on gender roles
7. **Parenting views** - Children timeline and philosophy
8. **Conflict resolution style** - Approach to disagreements

## File Structure
- `question_bank.json` - Main question bank with all questions and metadata
- Questions include both multiple choice and open-ended formats
- Each question includes a follow-up prompt for deeper conversation

## Adding Questions to Firestore

### Option 1: One-time Upload (Recommended for Initial Setup)

Add this code to your `DashboardViewModel.swift` or create a debug screen:

```swift
import SwiftUI

struct DebugActionsView: View {
    @State private var isUploading = false
    @State private var uploadStatus = ""

    var body: some View {
        VStack(spacing: 20) {
            Button("Upload Question Bank to Firestore") {
                Task {
                    isUploading = true
                    uploadStatus = "Uploading..."

                    do {
                        let service = QuestionBankService()
                        try await service.uploadQuestionBankToFirestore()
                        uploadStatus = "✅ Successfully uploaded questions!"
                    } catch {
                        uploadStatus = "❌ Error: \(error.localizedDescription)"
                    }

                    isUploading = false
                }
            }
            .disabled(isUploading)

            Text(uploadStatus)
                .font(.caption)
        }
        .padding()
    }
}
```

### Option 2: Command Line Script

Run this Swift script to upload questions:

```swift
// In a debug menu or temporary view:
Task {
    let service = QuestionBankService()
    try await service.uploadQuestionBankToFirestore()
    print("Questions uploaded successfully!")
}
```

### Option 3: Firebase Console (Manual)

1. Open Firebase Console → Firestore Database
2. Create collection: `questions`
3. For each question in `question_bank.json`, create a document with the question ID
4. Copy the fields from JSON to Firestore

## Firestore Structure

### Collection: `questions`
```
questions/
  q001/
    questionText: "How important is it to you that..."
    questionType: "multipleChoice"
    options: ["Extremely important...", "Very important...", ...]
    topic: "Religious values"
    followUpPrompt: "What aspects of religious practice..."
    isActive: true
    createdAt: timestamp
```

### Collection: `dailyQuestionAssignments`
```
dailyQuestionAssignments/
  2025-12-22/
    questionId: "q001"
    date: timestamp
    createdAt: timestamp
```

## Usage in Code

### Fetch Today's Question
```swift
let service = QuestionBankService()
if let todayQuestion = try await service.fetchTodayQuestion() {
    // Display question
}
```

### Assign Daily Question (Run once per day)
```swift
let service = QuestionBankService()
try await service.assignDailyQuestionToAllUsers()
```

### Fetch Random Question
```swift
let service = QuestionBankService()
let randomQuestion = try await service.fetchRandomQuestion()
```

### Fetch by Topic
```swift
let service = QuestionBankService()
let questions = try await service.fetchQuestionsByTopic(topic: "Religious values")
```

## Development Notes

- **IMPORTANT**: Only upload the question bank once. Running the upload multiple times will overwrite existing questions.
- For production, you should set up a Cloud Function to assign daily questions automatically
- Questions are marked as `isActive: true` by default. You can deactivate questions by setting this to `false`
- The follow-up prompts are designed to encourage deeper conversation between partners

## Extending the Question Bank

To add more questions:

1. Add new question objects to the `questions` array in `question_bank.json`
2. Follow the same structure:
   - Unique `id` (e.g., "q009", "q010")
   - Clear `questionText`
   - Appropriate `questionType` ("multipleChoice" or "openEnded")
   - Thoughtful `options` for multiple choice (null for open-ended)
   - Matching `topic` from the 8 core topics
   - Engaging `followUpPrompt`
3. Update `metadata.totalQuestions` count
4. Re-upload to Firestore using the `uploadQuestionBankToFirestore()` method

## Future Enhancements

- [ ] Add difficulty levels (starter, intermediate, deep)
- [ ] Add seasonal/themed questions (holidays, anniversaries)
- [ ] Track which questions users have answered
- [ ] Implement question rotation to avoid repeats
- [ ] Add admin panel for question management
- [ ] Implement A/B testing for question effectiveness
- [ ] Add analytics on which questions spark the most conversation
