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
            // Check if username is already taken
            let usernameQuery = db.collection("users")
                .whereField("username", isEqualTo: user.username)
                .limit(to: 1)

            let usernameSnapshot = try await usernameQuery.getDocuments()

            // If username exists and it's not the current user, throw error
            if !usernameSnapshot.isEmpty,
               let existingUser = usernameSnapshot.documents.first,
               existingUser.documentID != user.id {
                throw FirestoreError.usernameAlreadyExists
            }

            // Convert User to dictionary
            let encoder = Firestore.Encoder()
            let userData = try encoder.encode(user)

            try await db.collection("users").document(user.id).setData(userData)
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
                .whereField("username", isEqualTo: username)
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

    func sendPartnerRequest(from userId: String, senderUsername: String, to receiverUsername: String) async throws {
        // Check if receiver exists
        guard let receiver = try await getUserByUsername(receiverUsername) else {
            throw FirestoreError.userNotFound
        }

        let request = PartnerRequest(
            id: UUID().uuidString,
            senderId: userId,
            senderUsername: senderUsername,
            receiverUsername: receiverUsername,
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
                .whereField("receiverUsername", isEqualTo: username)
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

    // MARK: - Username Validation

    func isUsernameAvailable(_ username: String) async throws -> Bool {
        let querySnapshot = try await db.collection("users")
            .whereField("username", isEqualTo: username)
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
}
