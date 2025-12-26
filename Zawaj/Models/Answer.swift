//
//  Answer.swift
//  Zawaj
//
//  Created on 2025-12-23.
//

import Foundation

struct Answer: Codable, Identifiable {
    let id: Int
    let userId: String
    let questionId: Int
    let partnershipId: String
    let answerText: String
    let selectedOptions: [String]?
    let submittedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case questionId = "question_id"
        case partnershipId = "partnership_id"
        case answerText = "answer_text"
        case selectedOptions = "selected_options"
        case submittedAt = "submitted_at"
    }

    /// Creates a document ID from user ID and question ID
    static func createDocumentId(userId: String, questionId: Int) -> String {
        return "\(userId)_\(questionId)"
    }

    init(
        id: Int,
        userId: String,
        questionId: Int,
        partnershipId: String,
        answerText: String,
        selectedOptions: [String]? = nil,
        submittedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.questionId = questionId
        self.partnershipId = partnershipId
        self.answerText = answerText
        self.selectedOptions = selectedOptions
        self.submittedAt = submittedAt
    }
}
