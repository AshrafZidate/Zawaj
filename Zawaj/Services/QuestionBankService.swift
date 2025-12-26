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

    // MARK: - Fetch Topics

    /// Fetches all active topics ordered by their order field
    func fetchAllTopics() async throws -> [Topic] {
        // Note: Not filtering by archived_at since the field may not exist on all documents
        // If soft-delete is needed later, ensure all documents have archived_at: null
        let snapshot = try await db.collection("topics")
            .order(by: "order")
            .getDocuments()

        return try snapshot.documents.compactMap { doc in
            try parseFirestoreDocument(doc, as: Topic.self)
        }.filter { $0.archivedAt == nil }
    }

    /// Fetches only rankable topics (for priority ranking UI)
    func fetchRankableTopics() async throws -> [Topic] {
        let snapshot = try await db.collection("topics")
            .whereField("is_rankable", isEqualTo: true)
            .order(by: "order")
            .getDocuments()

        return try snapshot.documents.compactMap { doc in
            try parseFirestoreDocument(doc, as: Topic.self)
        }.filter { $0.archivedAt == nil }
    }

    /// Fetches a specific topic by ID
    func fetchTopic(id: Int) async throws -> Topic? {
        let doc = try await db.collection("topics").document(String(id)).getDocument()
        guard doc.exists else { return nil }
        return try parseFirestoreDocument(doc, as: Topic.self)
    }

    // MARK: - Fetch Subtopics

    /// Fetches all subtopics for a given topic
    func fetchSubtopics(forTopicId topicId: Int) async throws -> [Subtopic] {
        let snapshot = try await db.collection("subtopics")
            .whereField("topic_id", isEqualTo: topicId)
            .order(by: "order")
            .getDocuments()

        return try snapshot.documents.compactMap { doc in
            try parseFirestoreDocument(doc, as: Subtopic.self)
        }.filter { $0.archivedAt == nil }
    }

    /// Fetches a specific subtopic by ID
    func fetchSubtopic(id: Int) async throws -> Subtopic? {
        let doc = try await db.collection("subtopics").document(String(id)).getDocument()
        guard doc.exists else { return nil }
        return try parseFirestoreDocument(doc, as: Subtopic.self)
    }

    /// Fetches subtopic at a specific order position for a topic
    func fetchSubtopic(forTopicId topicId: Int, atOrder order: Int) async throws -> Subtopic? {
        let snapshot = try await db.collection("subtopics")
            .whereField("topic_id", isEqualTo: topicId)
            .whereField("order", isEqualTo: order)
            .getDocuments()

        guard let doc = snapshot.documents.first else { return nil }
        let subtopic = try parseFirestoreDocument(doc, as: Subtopic.self)
        return subtopic.archivedAt == nil ? subtopic : nil
    }

    // MARK: - Fetch Questions

    /// Fetches all questions for a given subtopic
    func fetchQuestions(forSubtopicId subtopicId: Int) async throws -> [Question] {
        let snapshot = try await db.collection("questions")
            .whereField("subtopic_id", isEqualTo: subtopicId)
            .order(by: "order")
            .getDocuments()

        return try snapshot.documents.compactMap { doc in
            try parseFirestoreDocument(doc, as: Question.self)
        }.filter { $0.archivedAt == nil }
    }

    /// Fetches questions filtered by gender (null gender means for everyone)
    func fetchQuestions(forSubtopicId subtopicId: Int, gender: Gender?) async throws -> [Question] {
        let allQuestions = try await fetchQuestions(forSubtopicId: subtopicId)

        // Filter questions: include if gender is nil (for everyone) or matches user's gender
        return allQuestions.filter { question in
            question.gender == nil || question.gender == gender
        }
    }

    /// Fetches a specific question by ID
    func fetchQuestion(id: Int) async throws -> Question? {
        let doc = try await db.collection("questions").document(String(id)).getDocument()
        guard doc.exists else { return nil }
        return try parseFirestoreDocument(doc, as: Question.self)
    }

    // MARK: - Branching Logic

    /// Determines if a question should be shown based on parent questions' follow_ups
    /// Returns true if this question is not a follow-up, or if the parent's answer triggers it
    func shouldShowQuestion(
        _ question: Question,
        allQuestions: [Question],
        previousAnswers: [Int: Answer]
    ) -> Bool {
        // Find any parent question that has this question in its follow_ups
        for parentQuestion in allQuestions {
            guard let followUps = parentQuestion.followUps else { continue }

            for followUp in followUps {
                if followUp.questionId == question.id {
                    // This question is a follow-up - check if parent's answer triggers it
                    guard let parentAnswer = previousAnswers[parentQuestion.id],
                          let parentOptions = parentQuestion.options else {
                        // Parent not answered yet
                        return false
                    }

                    // Find which option index the user selected
                    let selectedIndex = parentOptions.firstIndex(of: parentAnswer.answerText)

                    if let index = selectedIndex, followUp.answerIndices.contains(index) {
                        return true
                    }
                    return false
                }
            }
        }

        // Not a follow-up question, always show
        return true
    }

    /// Filters questions based on branching conditions and previous answers
    func filterQuestionsForDisplay(
        questions: [Question],
        previousAnswers: [Int: Answer],
        userGender: Gender?
    ) -> [Question] {
        return questions.filter { question in
            // First check gender filter
            if let questionGender = question.gender, questionGender != userGender {
                return false
            }
            // Then check if this question should show based on parent follow_ups
            return shouldShowQuestion(question, allQuestions: questions, previousAnswers: previousAnswers)
        }
    }

    // MARK: - Combined Topic Priority Calculation

    /// Calculates the combined topic order for a partnership based on both users' priorities
    /// Returns an array of topic IDs in priority order
    func calculateCombinedTopicOrder(
        userAPriorities: [String],
        userBPriorities: [String]
    ) async throws -> [Int] {
        // Fetch all topics to get their IDs and rankability
        let allTopics = try await fetchAllTopics()
        let rankableTopics = allTopics.filter { $0.isRankable }
        let nonRankableTopics = allTopics.filter { !$0.isRankable }

        // Create a mapping of topic name to ID
        let topicNameToId: [String: Int] = Dictionary(
            uniqueKeysWithValues: allTopics.map { ($0.name, $0.id) }
        )

        // Calculate scores for rankable topics
        var topicScores: [Int: Int] = [:]

        for (index, topicName) in userAPriorities.enumerated() {
            if let topicId = topicNameToId[topicName] {
                let score = 8 - index // Higher rank = higher score
                topicScores[topicId, default: 0] += score
            }
        }

        for (index, topicName) in userBPriorities.enumerated() {
            if let topicId = topicNameToId[topicName] {
                let score = 8 - index
                topicScores[topicId, default: 0] += score
            }
        }

        // Sort rankable topics by combined score (descending)
        let sortedRankableIds = rankableTopics
            .sorted { (topicScores[$0.id] ?? 0) > (topicScores[$1.id] ?? 0) }
            .map { $0.id }

        // Append non-rankable topics at the end in their natural order
        let nonRankableIds = nonRankableTopics.map { $0.id }

        return sortedRankableIds + nonRankableIds
    }

    // MARK: - Next Subtopic Assignment

    /// Gets the next subtopic to assign based on partnership progress
    func getNextSubtopic(progress: PartnershipProgress) async throws -> Subtopic? {
        // Iterate through topics in combined priority order
        for topicId in progress.combinedTopicOrder {
            // Get subtopic at current round
            if let subtopic = try await fetchSubtopic(forTopicId: topicId, atOrder: progress.currentRound) {
                // Check if not already completed
                if !progress.completedSubtopics.contains(subtopic.id) {
                    return subtopic
                }
            }
        }

        // All topics exhausted at this round, check if there are more rounds
        // Find the maximum number of subtopics across all topics
        var maxSubtopics = 0
        for topicId in progress.combinedTopicOrder {
            let subtopics = try await fetchSubtopics(forTopicId: topicId)
            maxSubtopics = max(maxSubtopics, subtopics.count)
        }

        if progress.currentRound < maxSubtopics {
            // There are more rounds available
            // This would require updating the progress.currentRound and trying again
            // Return nil to signal that the caller should increment the round
            return nil
        }

        // All subtopics in all topics are complete
        return nil
    }

    /// Checks if all subtopics are completed
    func isAllComplete(progress: PartnershipProgress) async throws -> Bool {
        // Get all subtopic IDs
        var allSubtopicIds: Set<Int> = []

        for topicId in progress.combinedTopicOrder {
            let subtopics = try await fetchSubtopics(forTopicId: topicId)
            allSubtopicIds.formUnion(subtopics.map { $0.id })
        }

        // Check if all are completed
        let completedSet = Set(progress.completedSubtopics)
        return allSubtopicIds.isSubset(of: completedSet)
    }

    // MARK: - Helper Methods

    private func parseFirestoreDocument<T: Decodable>(_ document: QueryDocumentSnapshot, as type: T.Type) throws -> T {
        let data = document.data()
        return try parseData(data, as: type)
    }

    private func parseFirestoreDocument<T: Decodable>(_ document: DocumentSnapshot, as type: T.Type) throws -> T {
        guard let data = document.data() else {
            throw FirestoreError.invalidData
        }
        return try parseData(data, as: type)
    }

    private func parseData<T: Decodable>(_ data: [String: Any], as type: T.Type) throws -> T {
        // Convert Firestore data to JSON-compatible format
        var jsonData = data

        // Handle Timestamp to Date conversion
        for (key, value) in data {
            if let timestamp = value as? Timestamp {
                jsonData[key] = timestamp.dateValue().iso8601String
            } else if value is NSNull {
                jsonData[key] = nil
            }
        }

        let jsonDataBytes = try JSONSerialization.data(withJSONObject: jsonData)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: jsonDataBytes)
    }
}

// MARK: - Date Extension

private extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
}
