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

    // Completion tracking fields
    var userCompletion: [String: Date]  // userId -> completion timestamp
    var bothCompleted: Bool
    var bothCompletedAt: Date?
    var nextAssignmentScheduled: Bool
    var nextScheduledDate: String?  // YYYY-MM-DD of next assignment

    enum CodingKeys: String, CodingKey {
        case id
        case partnershipId = "partnership_id"
        case date
        case subtopicId = "subtopic_id"
        case createdAt = "created_at"
        case userCompletion = "user_completion"
        case bothCompleted = "both_completed"
        case bothCompletedAt = "both_completed_at"
        case nextAssignmentScheduled = "next_assignment_scheduled"
        case nextScheduledDate = "next_scheduled_date"
    }

    init(id: Int, partnershipId: String, date: String, subtopicId: Int, createdAt: Date = Date(),
         userCompletion: [String: Date] = [:], bothCompleted: Bool = false, bothCompletedAt: Date? = nil,
         nextAssignmentScheduled: Bool = false, nextScheduledDate: String? = nil) {
        self.id = id
        self.partnershipId = partnershipId
        self.date = date
        self.subtopicId = subtopicId
        self.createdAt = createdAt
        self.userCompletion = userCompletion
        self.bothCompleted = bothCompleted
        self.bothCompletedAt = bothCompletedAt
        self.nextAssignmentScheduled = nextAssignmentScheduled
        self.nextScheduledDate = nextScheduledDate
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
