//
//  Topic.swift
//  Zawaj
//
//  Created on 2025-12-26.
//

import Foundation

struct Topic: Codable, Identifiable {
    let id: Int
    let name: String
    let order: Int
    let isRankable: Bool
    let createdAt: Date
    let archivedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case order
        case isRankable = "is_rankable"
        case createdAt = "created_at"
        case archivedAt = "archived_at"
    }

    init(id: Int, name: String, order: Int, isRankable: Bool, createdAt: Date = Date(), archivedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.order = order
        self.isRankable = isRankable
        self.createdAt = createdAt
        self.archivedAt = archivedAt
    }
}
