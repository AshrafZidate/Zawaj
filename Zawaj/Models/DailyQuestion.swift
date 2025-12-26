//
//  DailyQuestion.swift
//  Zawaj
//
//  Created on 2025-12-21.
//
//  DEPRECATED: This model is kept for backwards compatibility.
//  New implementations should use Question, Subtopic, and Topic models
//  with DailySubtopicAssignment for daily question assignments.
//

import Foundation

// Note: QuestionType enum has been moved to Question.swift
// This file is kept for any legacy code that may reference DailyQuestion

struct DailyQuestion: Codable, Identifiable {
    let id: String
    let questionText: String
    let questionType: LegacyQuestionType
    let options: [String]?
    let topic: String
    let date: Date
    let createdAt: Date
}

// Renamed to avoid conflict with new QuestionType in Question.swift
enum LegacyQuestionType: String, Codable {
    case multipleChoice
    case openEnded
}
