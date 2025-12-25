//
//  PartnerRequest.swift
//  Zawaj
//
//  Created on 2025-12-21.
//

import Foundation

struct PartnerRequest: Codable, Identifiable {
    var id: String
    let senderId: String
    let senderFullName: String?
    let senderUsername: String
    let receiverUsername: String
    var status: String // "pending", "accepted", "rejected"
    let createdAt: Date
    var respondedAt: Date?

    /// Display name for the sender - uses full name if available, otherwise username
    var senderDisplayName: String {
        if let fullName = senderFullName, !fullName.isEmpty {
            return fullName
        }
        return senderUsername
    }
}
