//
//  QuestionBankService.swift
//  Zawaj
//
//  Created on 2025-12-22.
//

import Foundation
import FirebaseFirestore

class QuestionBankService {
    private let db = Firestore.firestore()

    // MARK: - Question Bank Structure

    struct QuestionBankJSON: Codable {
        let questions: [QuestionJSON]
        let metadata: QuestionBankMetadata
    }

    struct QuestionJSON: Codable {
        let id: String
        let questionText: String
        let questionType: String
        let options: [String]?
        let topic: String
        let followUpPrompt: String
    }

    struct QuestionBankMetadata: Codable {
        let version: String
        let totalQuestions: Int
        let topics: [String]
        let description: String
        let createdDate: String
    }

    // MARK: - Load Question Bank

    /// Loads the question bank from the bundled JSON file
    func loadQuestionBankFromJSON() -> QuestionBankJSON? {
        guard let url = Bundle.main.url(forResource: "question_bank", withExtension: "json") else {
            print("Error: question_bank.json not found in bundle")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let questionBank = try decoder.decode(QuestionBankJSON.self, from: data)
            return questionBank
        } catch {
            print("Error decoding question bank: \(error)")
            return nil
        }
    }

    // MARK: - Upload to Firestore

    /// Uploads all questions from the question bank to Firestore
    /// WARNING: Only run this once to populate the database
    func uploadQuestionBankToFirestore() async throws {
        guard let questionBank = loadQuestionBankFromJSON() else {
            throw NSError(domain: "QuestionBankService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load question bank"])
        }

        let batch = db.batch()

        for question in questionBank.questions {
            let questionRef = db.collection("questions").document(question.id)

            var questionData: [String: Any] = [
                "questionText": question.questionText,
                "questionType": question.questionType,
                "topic": question.topic,
                "followUpPrompt": question.followUpPrompt,
                "createdAt": FieldValue.serverTimestamp(),
                "isActive": true
            ]

            if let options = question.options {
                questionData["options"] = options
            }

            batch.setData(questionData, forDocument: questionRef)
        }

        // Upload metadata
        let metadataRef = db.collection("questionBankMetadata").document("current")
        let metadataData: [String: Any] = [
            "version": questionBank.metadata.version,
            "totalQuestions": questionBank.metadata.totalQuestions,
            "topics": questionBank.metadata.topics,
            "description": questionBank.metadata.description,
            "uploadedAt": FieldValue.serverTimestamp()
        ]
        batch.setData(metadataData, forDocument: metadataRef)

        try await batch.commit()
        print("Successfully uploaded \(questionBank.questions.count) questions to Firestore")
    }

    // MARK: - Fetch Random Question

    /// Fetches a random question from Firestore
    func fetchRandomQuestion() async throws -> DailyQuestion {
        let snapshot = try await db.collection("questions")
            .whereField("isActive", isEqualTo: true)
            .getDocuments()

        guard !snapshot.documents.isEmpty else {
            throw NSError(domain: "QuestionBankService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No questions available"])
        }

        // Pick a random question
        let randomDoc = snapshot.documents.randomElement()!
        return try parseDailyQuestion(from: randomDoc)
    }

    /// Fetches a specific question by ID
    func fetchQuestion(id: String) async throws -> DailyQuestion {
        let doc = try await db.collection("questions").document(id).getDocument()

        guard doc.exists else {
            throw NSError(domain: "QuestionBankService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Question not found"])
        }

        return try parseDailyQuestion(from: doc)
    }

    /// Fetches questions by topic
    func fetchQuestionsByTopic(topic: String) async throws -> [DailyQuestion] {
        let snapshot = try await db.collection("questions")
            .whereField("topic", isEqualTo: topic)
            .whereField("isActive", isEqualTo: true)
            .getDocuments()

        return try snapshot.documents.map { try parseDailyQuestion(from: $0) }
    }

    // MARK: - Daily Question Assignment

    /// Assigns today's question to all users
    /// This should be called by a Cloud Function or scheduled task
    func assignDailyQuestionToAllUsers() async throws {
        let question = try await fetchRandomQuestion()
        let today = Calendar.current.startOfDay(for: Date())

        // Create a daily question assignment document
        let assignmentRef = db.collection("dailyQuestionAssignments").document(formatDate(today))

        try await assignmentRef.setData([
            "questionId": question.id,
            "date": Timestamp(date: today),
            "createdAt": FieldValue.serverTimestamp()
        ])

        print("Assigned question \(question.id) for \(formatDate(today))")
    }

    /// Fetches today's assigned question
    func fetchTodayQuestion() async throws -> DailyQuestion? {
        let today = Calendar.current.startOfDay(for: Date())
        let todayString = formatDate(today)

        let doc = try await db.collection("dailyQuestionAssignments")
            .document(todayString)
            .getDocument()

        guard doc.exists,
              let questionId = doc.data()?["questionId"] as? String else {
            return nil
        }

        return try await fetchQuestion(id: questionId)
    }

    // MARK: - Helper Methods

    private func parseDailyQuestion(from document: QueryDocumentSnapshot) throws -> DailyQuestion {
        let data = document.data()

        guard let questionText = data["questionText"] as? String,
              let questionTypeString = data["questionType"] as? String,
              let topic = data["topic"] as? String else {
            throw NSError(domain: "QuestionBankService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid question data"])
        }

        let questionType = questionTypeString == "multipleChoice" ? QuestionType.multipleChoice : QuestionType.openEnded
        let options = data["options"] as? [String]
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()

        return DailyQuestion(
            id: document.documentID,
            questionText: questionText,
            questionType: questionType,
            options: options,
            topic: topic,
            date: Date(),
            createdAt: createdAt
        )
    }

    private func parseDailyQuestion(from document: DocumentSnapshot) throws -> DailyQuestion {
        guard let data = document.data() else {
            throw NSError(domain: "QuestionBankService", code: 5, userInfo: [NSLocalizedDescriptionKey: "Document data is nil"])
        }

        guard let questionText = data["questionText"] as? String,
              let questionTypeString = data["questionType"] as? String,
              let topic = data["topic"] as? String else {
            throw NSError(domain: "QuestionBankService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid question data"])
        }

        let questionType = questionTypeString == "multipleChoice" ? QuestionType.multipleChoice : QuestionType.openEnded
        let options = data["options"] as? [String]
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()

        return DailyQuestion(
            id: document.documentID,
            questionText: questionText,
            questionType: questionType,
            options: options,
            topic: topic,
            date: Date(),
            createdAt: createdAt
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
