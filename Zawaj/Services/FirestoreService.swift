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
        let batch = db.batch()

        // Update request status
        let requestRef = db.collection("partnerRequests").document(requestId)
        batch.updateData([
            "status": "accepted",
            "respondedAt": Timestamp(date: Date())
        ], forDocument: requestRef)

        // Update both users' partner status
        let currentUserRef = db.collection("users").document(currentUserId)
        batch.updateData([
            "partnerId": partnerUserId,
            "partnerConnectionStatus": PartnerStatus.connected.rawValue,
            "updatedAt": Timestamp(date: Date())
        ], forDocument: currentUserRef)

        let partnerUserRef = db.collection("users").document(partnerUserId)
        batch.updateData([
            "partnerId": currentUserId,
            "partnerConnectionStatus": PartnerStatus.connected.rawValue,
            "updatedAt": Timestamp(date: Date())
        ], forDocument: partnerUserRef)

        // Create couple document
        let coupleId = [currentUserId, partnerUserId].sorted().joined(separator: "_")
        let coupleRef = db.collection("couples").document(coupleId)
        batch.setData([
            "user1Id": currentUserId,
            "user2Id": partnerUserId,
            "connectedAt": Timestamp(date: Date()),
            "currentQuestionId": NSNull(),
            "questionHistory": []
        ], forDocument: coupleRef)

        do {
            try await batch.commit()
        } catch {
            throw FirestoreError.unknown(error.localizedDescription)
        }
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

    // MARK: - Answers

    func submitAnswer(_ answer: Answer) async throws {
        do {
            let encoder = Firestore.Encoder()
            let answerData = try encoder.encode(answer)

            // Use a composite ID of userId_questionId for easy querying
            let documentId = "\(answer.userId)_\(answer.questionId)"
            try await db.collection("answers").document(documentId).setData(answerData)
        } catch {
            throw FirestoreError.unknown(error.localizedDescription)
        }
    }

    func getAnswer(userId: String, questionId: String) async throws -> Answer? {
        do {
            let documentId = "\(userId)_\(questionId)"
            let document = try await db.collection("answers").document(documentId).getDocument()

            guard document.exists else {
                return nil
            }

            let decoder = Firestore.Decoder()
            let answer = try decoder.decode(Answer.self, from: document.data() ?? [:])
            return answer
        } catch {
            throw FirestoreError.unknown(error.localizedDescription)
        }
    }

    func hasUserAnswered(userId: String, questionId: String) async throws -> Bool {
        let answer = try await getAnswer(userId: userId, questionId: questionId)
        return answer != nil
    }

    func getUserAnswersForQuestion(questionId: String, userIds: [String]) async throws -> [String: Answer] {
        var answers: [String: Answer] = [:]

        for userId in userIds {
            if let answer = try await getAnswer(userId: userId, questionId: questionId) {
                answers[userId] = answer
            }
        }

        return answers
    }

    // MARK: - Daily Questions

    func getTodayQuestion() async throws -> DailyQuestion? {
        do {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

            let querySnapshot = try await db.collection("dailyQuestions")
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: today))
                .whereField("date", isLessThan: Timestamp(date: tomorrow))
                .limit(to: 1)
                .getDocuments()

            guard let document = querySnapshot.documents.first else {
                return nil
            }

            let decoder = Firestore.Decoder()
            let question = try decoder.decode(DailyQuestion.self, from: document.data())
            return question
        } catch {
            throw FirestoreError.unknown(error.localizedDescription)
        }
    }
}
