//
//  Subtopic.swift
//  Zawaj
//
//  Created on 2025-12-26.
//

import Foundation

struct Subtopic: Codable, Identifiable {
    let id: Int
    let topicId: Int
    let name: String
    let order: Int
    let createdAt: Date
    let archivedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case topicId = "topic_id"
        case name
        case order
        case createdAt = "created_at"
        case archivedAt = "archived_at"
    }

    init(id: Int, topicId: Int, name: String, order: Int, createdAt: Date = Date(), archivedAt: Date? = nil) {
        self.id = id
        self.topicId = topicId
        self.name = name
        self.order = order
        self.createdAt = createdAt
        self.archivedAt = archivedAt
    }
}
