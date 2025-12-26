//
//  PartnershipProgress.swift
//  Zawaj
//
//  Created on 2025-12-26.
//

import Foundation

struct PartnershipProgress: Codable, Identifiable {
    let id: Int
    let partnershipId: String  // Format: "MaleId-FemaleId"
    let userIds: [String]
    var combinedTopicOrder: [Int]
    var currentRound: Int
    var completedSubtopics: [Int]
    var isComplete: Bool
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case partnershipId = "partnership_id"
        case userIds = "user_ids"
        case combinedTopicOrder = "combined_topic_order"
        case currentRound = "current_round"
        case completedSubtopics = "completed_subtopics"
        case isComplete = "is_complete"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: Int,
        partnershipId: String,
        userIds: [String],
        combinedTopicOrder: [Int],
        currentRound: Int = 1,
        completedSubtopics: [Int] = [],
        isComplete: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.partnershipId = partnershipId
        self.userIds = userIds
        self.combinedTopicOrder = combinedTopicOrder
        self.currentRound = currentRound
        self.completedSubtopics = completedSubtopics
        self.isComplete = isComplete
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Creates a partnership ID from male and female user IDs
    static func createPartnershipId(maleId: String, femaleId: String) -> String {
        return "\(maleId)-\(femaleId)"
    }
}
