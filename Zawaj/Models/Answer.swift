//
//  Answer.swift
//  Zawaj
//
//  Created on 2025-12-23.
//

import Foundation

struct Answer: Codable, Identifiable {
    let id: String
    let userId: String
    let questionId: String
    let answerText: String
    let submittedAt: Date

    // Computed property to create unique ID
    var computedId: String {
        "\(userId)_\(questionId)"
    }

    // Initialize with auto-generated ID
    init(id: String = UUID().uuidString, userId: String, questionId: String, answerText: String, submittedAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.questionId = questionId
        self.answerText = answerText
        self.submittedAt = submittedAt
    }
}
