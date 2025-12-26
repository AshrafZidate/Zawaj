//
//  Question.swift
//  Zawaj
//
//  Created on 2025-12-26.
//

import Foundation

enum QuestionType: String, Codable {
    case singleChoice = "single_choice"  // Always radio buttons (pick one), can trigger branching
    case multiChoice = "multi_choice"    // User pref: checkboxes (pick multiple) OR free text
    case openEnded = "open_ended"        // User pref: radio buttons (pick one) OR free text
}

enum Gender: String, Codable {
    case male
    case female
}

struct FollowUp: Codable {
    let answerIndices: [Int]  // Which option indices trigger this follow-up
    let questionId: Int       // The follow-up question ID

    enum CodingKeys: String, CodingKey {
        case answerIndices = "answerIndices"
        case questionId = "questionId"
    }
}

struct Question: Codable, Identifiable {
    let id: Int
    let subtopicId: Int
    let questionText: String
    let questionType: QuestionType
    let options: [String]?
    let order: Int
    let gender: Gender?
    let followUps: [FollowUp]?  // For single_choice questions that trigger branching
    let createdAt: Date
    let archivedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case subtopicId = "subtopic_id"
        case questionText = "question_text"
        case questionType = "question_type"
        case options
        case order
        case gender
        case followUps = "follow_ups"
        case createdAt = "created_at"
        case archivedAt = "archived_at"
    }

    init(
        id: Int,
        subtopicId: Int,
        questionText: String,
        questionType: QuestionType,
        options: [String]? = nil,
        order: Int,
        gender: Gender? = nil,
        followUps: [FollowUp]? = nil,
        createdAt: Date = Date(),
        archivedAt: Date? = nil
    ) {
        self.id = id
        self.subtopicId = subtopicId
        self.questionText = questionText
        self.questionType = questionType
        self.options = options
        self.order = order
        self.gender = gender
        self.followUps = followUps
        self.createdAt = createdAt
        self.archivedAt = archivedAt
    }
}
