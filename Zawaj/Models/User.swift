//
//  User.swift
//  Zawaj
//
//  Created on 2025-12-20.
//

import Foundation

enum PartnerStatus: String, Codable {
    case none = "none"
    case pending = "pending"
    case connected = "connected"
    case rejected = "rejected"
}

struct User: Codable, Identifiable, Equatable {
    let id: String // Firebase UID
    var email: String
    var phoneNumber: String
    var isEmailVerified: Bool
    var isPhoneVerified: Bool

    // Profile data
    var fullName: String
    var username: String
    var gender: String
    var birthday: Date
    var relationshipStatus: String
    var marriageTimeline: String
    var topicPriorities: [String]

    // Partner connection (supports multiple partners)
    var partnerIds: [String]
    var partnerId: String? // Deprecated: kept for backward compatibility
    var partnerConnectionStatus: PartnerStatus

    // Settings
    var answerPreference: String
    var createdAt: Date
    var updatedAt: Date
    var photoURL: String?

    init(
        id: String,
        email: String,
        phoneNumber: String = "",
        isEmailVerified: Bool = false,
        isPhoneVerified: Bool = false,
        fullName: String = "",
        username: String = "",
        gender: String = "",
        birthday: Date = Date(),
        relationshipStatus: String = "",
        marriageTimeline: String = "",
        topicPriorities: [String] = [],
        partnerIds: [String] = [],
        partnerId: String? = nil,
        partnerConnectionStatus: PartnerStatus = .none,
        answerPreference: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        photoURL: String? = nil
    ) {
        self.id = id
        self.email = email
        self.phoneNumber = phoneNumber
        self.isEmailVerified = isEmailVerified
        self.isPhoneVerified = isPhoneVerified
        self.fullName = fullName
        self.username = username
        self.gender = gender
        self.birthday = birthday
        self.relationshipStatus = relationshipStatus
        self.marriageTimeline = marriageTimeline
        self.topicPriorities = topicPriorities
        self.partnerIds = partnerIds
        self.partnerId = partnerId
        self.partnerConnectionStatus = partnerConnectionStatus
        self.answerPreference = answerPreference
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.photoURL = photoURL
    }
}
