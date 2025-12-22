//
//  DailyQuestion.swift
//  Zawaj
//
//  Created on 2025-12-21.
//

import Foundation

enum QuestionType: String, Codable {
    case multipleChoice
    case openEnded
}

struct DailyQuestion: Codable, Identifiable {
    let id: String
    let questionText: String
    let questionType: QuestionType
    let options: [String]? // For multiple choice
    let topic: String
    let date: Date
    let createdAt: Date
}
