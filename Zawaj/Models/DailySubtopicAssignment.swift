//
//  DailySubtopicAssignment.swift
//  Zawaj
//
//  Created on 2025-12-26.
//

import Foundation

struct DailySubtopicAssignment: Codable, Identifiable {
    let id: Int
    let partnershipId: String
    let date: String  // Format: YYYY-MM-DD
    let subtopicId: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case partnershipId = "partnership_id"
        case date
        case subtopicId = "subtopic_id"
        case createdAt = "created_at"
    }

    init(id: Int, partnershipId: String, date: String, subtopicId: Int, createdAt: Date = Date()) {
        self.id = id
        self.partnershipId = partnershipId
        self.date = date
        self.subtopicId = subtopicId
        self.createdAt = createdAt
    }

    /// Creates a document ID from partnership ID and date
    static func createDocumentId(partnershipId: String, date: String) -> String {
        return "\(partnershipId)_\(date)"
    }

    /// Gets today's date string in YYYY-MM-DD format
    static func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
