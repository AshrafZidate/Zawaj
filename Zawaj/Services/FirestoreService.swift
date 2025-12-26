//
//  FirestoreService.swift
//  Zawaj
//
//  Created on 2025-12-20.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

enum FirestoreError: Error, LocalizedError {
    case userNotFound
    case usernameAlreadyExists
    case partnerNotFound
    case invalidData
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User profile not found."
        case .usernameAlreadyExists:
            return "This username is already taken."
        case .partnerNotFound:
            return "Partner not found."
        case .invalidData:
            return "Invalid data format."
        case .unknown(let message):
            return message
        }
    }
}

class FirestoreService {
    private let db = Firestore.firestore()

    // MARK: - User Profile

    func saveUserProfile(_ user: User) async throws {
        do {
            // Ensure username is lowercase for case-insensitive storage
            var userToSave = user
            userToSave.username = user.username.lowercased()

            // Check if username is already taken
            let usernameQuery = db.collection("users")
                .whereField("username", isEqualTo: userToSave.username)
                .limit(to: 1)

            let usernameSnapshot = try await usernameQuery.getDocuments()

            // If username exists and it's not the current user, throw error
            if !usernameSnapshot.isEmpty,
               let existingUser = usernameSnapshot.documents.first,
               existingUser.documentID != userToSave.id {
                throw FirestoreError.usernameAlreadyExists
            }

            // Convert User to dictionary
            let encoder = Firestore.Encoder()
            let userData = try encoder.encode(userToSave)

            try await db.collection("users").document(userToSave.id).setData(userData)
        } catch let error as FirestoreError {
            throw error
        } catch {
            throw FirestoreError.unknown(error.localizedDescription)
        }
    }

    func getUserProfile(userId: String) async throws -> User {
        do {
            let document = try await db.collection("users").document(userId).getDocument()

            guard document.exists else {
                throw FirestoreError.userNotFound
            }

            let decoder = Firestore.Decoder()
            let user = try decoder.decode(User.self, from: document.data() ?? [:])
            return user
        } catch let error as FirestoreError {
            throw error
        } catch {
            throw FirestoreError.unknown(error.localizedDescription)
        }
    }

    func updateUserProfile(userId: String, updates: [String: Any]) async throws {
        var mutableUpdates = updates
        mutableUpdates["updatedAt"] = Timestamp(date: Date())

        do {
            try await db.collection("users").document(userId).updateData(mutableUpdates)
        } catch {
            throw FirestoreError.unknown(error.localizedDescription)
        }
    }

    func getUserByUsername(_ username: String) async throws -> User? {
        do {
            let querySnapshot = try await db.collection("users")
                .whereField("username", isEqualTo: username.lowercased())
                .limit(to: 1)
                .getDocuments()

            guard let document = querySnapshot.documents.first else {
                return nil
            }

            let decoder = Firestore.Decoder()
            let user = try decoder.decode(User.self, from: document.data())
            return user
        } catch {
            throw FirestoreError.unknown(error.localizedDescription)
        }
    }

    func getUserByEmail(_ email: String) async throws -> User? {
        do {
            let querySnapshot = try await db.collection("users")
                .whereField("email", isEqualTo: email)
                .limit(to: 1)
                .getDocuments()

            guard let document = querySnapshot.documents.first else {
                return nil
            }

            let decoder = Firestore.Decoder()
            let user = try decoder.decode(User.self, from: document.data())
            return user
        } catch {
            throw FirestoreError.unknown(error.localizedDescription)
        }
    }

    // MARK: - Real-time Listeners

    func observeUserProfile(userId: String, onChange: @escaping (User?) -> Void) -> ListenerRegistration {
        return db.collection("users").document(userId).addSnapshotListener { snapshot, error in
            guard let snapshot = snapshot, snapshot.exists else {
                onChange(nil)
                return
            }

            do {
                let decoder = Firestore.Decoder()
                let user = try decoder.decode(User.self, from: snapshot.data() ?? [:])
                onChange(user)
            } catch {
                print("Error decoding user: \(error)")
                onChange(nil)
            }
        }
    }

    func observePartnerProfile(partnerId: String, onChange: @escaping (User?) -> Void) -> ListenerRegistration {
        return observeUserProfile(userId: partnerId, onChange: onChange)
    }

    // MARK: - Partner Requests

    func sendPartnerRequest(request: PartnerRequest, receiverId: String) async throws {
        do {
            let encoder = Firestore.Encoder()
            var requestData = try encoder.encode(request)
            requestData["receiverId"] = receiverId

            try await db.collection("partnerRequests").document(request.id).setData(requestData)
        } catch {
            throw FirestoreError.unknown(error.localizedDescription)
        }
    }

    func sendPartnerRequest(from userId: String, senderFullName: String, senderUsername: String, to receiverUsername: String) async throws {
        // Check if receiver exists (getUserByUsername already lowercases)
        guard let receiver = try await getUserByUsername(receiverUsername) else {
            throw FirestoreError.userNotFound
        }

        let request = PartnerRequest(
            id: UUID().uuidString,
            senderId: userId,
            senderFullName: senderFullName,
            senderUsername: senderUsername.lowercased(),
            receiverUsername: receiverUsername.lowercased(),
            status: "pending",
            createdAt: Date(),
            respondedAt: nil
        )

        try await sendPartnerRequest(request: request, receiverId: receiver.id)
    }

    func acceptPartnerRequest(requestId: String, currentUserId: String, partnerUserId: String) async throws {
        // Update current user's partner status (only update own document due to security rules)
        try await db.collection("users").document(currentUserId).updateData([
            "partnerIds": FieldValue.arrayUnion([partnerUserId]),
            "partnerId": partnerUserId,
            "partnerConnectionStatus": PartnerStatus.connected.rawValue,
            "updatedAt": Timestamp(date: Date())
        ])

        // Try to update partner's document (may fail due to security rules, that's ok)
        try? await db.collection("users").document(partnerUserId).updateData([
            "partnerIds": FieldValue.arrayUnion([currentUserId]),
            "partnerId": currentUserId,
            "partnerConnectionStatus": PartnerStatus.connected.rawValue,
            "updatedAt": Timestamp(date: Date())
        ])

        // Update request status (may fail due to security rules, that's ok)
        try? await db.collection("partnerRequests").document(requestId).updateData([
            "status": "accepted",
            "respondedAt": Timestamp(date: Date())
        ])
    }

    func rejectPartnerRequest(requestId: String) async throws {
        do {
            try await db.collection("partnerRequests").document(requestId).updateData([
                "status": "rejected",
                "respondedAt": Timestamp(date: Date())
            ])
        } catch {
            throw FirestoreError.unknown(error.localizedDescription)
        }
    }

    func getPendingPartnerRequests(for username: String) async throws -> [PartnerRequest] {
        do {
            let querySnapshot = try await db.collection("partnerRequests")
                .whereField("receiverUsername", isEqualTo: username.lowercased())
                .whereField("status", isEqualTo: "pending")
                .getDocuments()

            let decoder = Firestore.Decoder()
            return try querySnapshot.documents.map { document in
                var request = try decoder.decode(PartnerRequest.self, from: document.data())
                request.id = document.documentID
                return request
            }
        } catch {
            throw FirestoreError.unknown(error.localizedDescription)
        }
    }

    func hasPendingPartnerRequest(from senderUsername: String, to receiverUsername: String) async throws -> Bool {
        let querySnapshot = try await db.collection("partnerRequests")
            .whereField("senderUsername", isEqualTo: senderUsername.lowercased())
            .whereField("receiverUsername", isEqualTo: receiverUsername.lowercased())
            .whereField("status", isEqualTo: "pending")
            .getDocuments()

        return !querySnapshot.documents.isEmpty
    }

    // MARK: - Username Validation

    func isUsernameAvailable(_ username: String) async throws -> Bool {
        let querySnapshot = try await db.collection("users")
            .whereField("username", isEqualTo: username.lowercased())
            .limit(to: 1)
            .getDocuments()

        return querySnapshot.isEmpty
    }

    // MARK: - User Deletion

    func deleteUserProfile(userId: String) async throws {
        do {
            try await db.collection("users").document(userId).delete()
        } catch {
            throw FirestoreError.unknown(error.localizedDescription)
        }
    }

    // MARK: - Partnership Progress

    /// Gets or creates partnership progress for a given partnership
    func getOrCreatePartnershipProgress(
        partnershipId: String,
        userIds: [String],
        combinedTopicOrder: [Int]
    ) async throws -> PartnershipProgress {
        let docRef = db.collection("partnership_progress").document(partnershipId)
        let document = try await docRef.getDocument()

        if document.exists {
            // Return existing progress
            let decoder = Firestore.Decoder()
            return try decoder.decode(PartnershipProgress.self, from: document.data() ?? [:])
        }

        // Create new progress
        let newProgress = PartnershipProgress(
            id: partnershipId.hashValue,
            partnershipId: partnershipId,
            userIds: userIds,
            combinedTopicOrder: combinedTopicOrder,
            currentRound: 1,
            completedSubtopics: [],
            isComplete: false,
            createdAt: Date(),
            updatedAt: Date()
        )

        let encoder = Firestore.Encoder()
        let progressData = try encoder.encode(newProgress)
        try await docRef.setData(progressData)

        return newProgress
    }

    /// Gets partnership progress for a partnership ID
    func getPartnershipProgress(partnershipId: String) async throws -> PartnershipProgress? {
        let document = try await db.collection("partnership_progress")
            .document(partnershipId)
            .getDocument()

        guard document.exists else { return nil }

        let decoder = Firestore.Decoder()
        return try decoder.decode(PartnershipProgress.self, from: document.data() ?? [:])
    }

    /// Updates partnership progress
    func updatePartnershipProgress(_ progress: PartnershipProgress) async throws {
        var updatedProgress = progress
        updatedProgress.updatedAt = Date()

        let encoder = Firestore.Encoder()
        let progressData = try encoder.encode(updatedProgress)

        try await db.collection("partnership_progress")
            .document(progress.partnershipId)
            .setData(progressData)
    }

    /// Marks a subtopic as completed for a partnership
    func markSubtopicCompleted(partnershipId: String, subtopicId: Int) async throws {
        try await db.collection("partnership_progress")
            .document(partnershipId)
            .updateData([
                "completed_subtopics": FieldValue.arrayUnion([subtopicId]),
                "updated_at": Timestamp(date: Date())
            ])
    }

    /// Increments the current round for a partnership
    func incrementPartnershipRound(partnershipId: String) async throws {
        try await db.collection("partnership_progress")
            .document(partnershipId)
            .updateData([
                "current_round": FieldValue.increment(Int64(1)),
                "updated_at": Timestamp(date: Date())
            ])
    }

    /// Marks partnership as complete
    func markPartnershipComplete(partnershipId: String) async throws {
        try await db.collection("partnership_progress")
            .document(partnershipId)
            .updateData([
                "is_complete": true,
                "updated_at": Timestamp(date: Date())
            ])
    }

    /// Updates the combined topic order for a partnership (when rankings change)
    func updateCombinedTopicOrder(partnershipId: String, newOrder: [Int]) async throws {
        try await db.collection("partnership_progress")
            .document(partnershipId)
            .updateData([
                "combined_topic_order": newOrder,
                "updated_at": Timestamp(date: Date())
            ])
    }

    // MARK: - Daily Subtopic Assignments

    /// Gets or creates today's subtopic assignment for a partnership
    func getTodaySubtopicAssignment(partnershipId: String) async throws -> DailySubtopicAssignment? {
        let today = formatDate(Date())
        let documentId = "\(partnershipId)_\(today)"

        let document = try await db.collection("daily_subtopic_assignments")
            .document(documentId)
            .getDocument()

        guard document.exists else { return nil }

        let decoder = Firestore.Decoder()
        return try decoder.decode(DailySubtopicAssignment.self, from: document.data() ?? [:])
    }

    /// Creates a daily subtopic assignment
    func createDailySubtopicAssignment(
        partnershipId: String,
        subtopicId: Int
    ) async throws -> DailySubtopicAssignment {
        let today = formatDate(Date())
        let documentId = "\(partnershipId)_\(today)"

        let assignment = DailySubtopicAssignment(
            id: documentId.hashValue,
            partnershipId: partnershipId,
            date: today,
            subtopicId: subtopicId,
            createdAt: Date()
        )

        let encoder = Firestore.Encoder()
        let assignmentData = try encoder.encode(assignment)

        try await db.collection("daily_subtopic_assignments")
            .document(documentId)
            .setData(assignmentData)

        return assignment
    }

    // MARK: - Answers (Updated)

    /// Gets all answers for a user in a specific subtopic
    func getAnswersForSubtopic(userId: String, subtopicId: Int, questionIds: [Int]) async throws -> [Int: Answer] {
        var answers: [Int: Answer] = [:]

        for questionId in questionIds {
            let documentId = Answer.createDocumentId(userId: userId, questionId: questionId)
            let document = try await db.collection("answers").document(documentId).getDocument()

            if document.exists {
                let decoder = Firestore.Decoder()
                let answer = try decoder.decode(Answer.self, from: document.data() ?? [:])
                answers[questionId] = answer
            }
        }

        return answers
    }

    /// Submits an answer (updated for new Answer model)
    func submitAnswer(
        userId: String,
        questionId: Int,
        partnershipId: String,
        answerText: String,
        selectedOptions: [String]? = nil
    ) async throws {
        let documentId = Answer.createDocumentId(userId: userId, questionId: questionId)

        let answer = Answer(
            id: documentId.hashValue,
            userId: userId,
            questionId: questionId,
            partnershipId: partnershipId,
            answerText: answerText,
            selectedOptions: selectedOptions,
            submittedAt: Date()
        )

        let encoder = Firestore.Encoder()
        let answerData = try encoder.encode(answer)

        try await db.collection("answers").document(documentId).setData(answerData)
    }

    /// Gets a specific answer by user and question ID
    func getAnswer(userId: String, questionId: Int) async throws -> Answer? {
        let documentId = Answer.createDocumentId(userId: userId, questionId: questionId)
        let document = try await db.collection("answers").document(documentId).getDocument()

        guard document.exists else { return nil }

        let decoder = Firestore.Decoder()
        return try decoder.decode(Answer.self, from: document.data() ?? [:])
    }

    /// Checks if both partners have answered all questions in a subtopic
    func haveBothPartnersCompletedSubtopic(
        partnerIds: [String],
        questionIds: [Int]
    ) async throws -> Bool {
        for partnerId in partnerIds {
            for questionId in questionIds {
                let answer = try await getAnswer(userId: partnerId, questionId: questionId)
                if answer == nil {
                    return false
                }
            }
        }
        return true
    }

    // MARK: - Helper Methods

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
