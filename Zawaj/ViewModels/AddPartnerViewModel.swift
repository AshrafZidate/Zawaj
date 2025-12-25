//
//  AddPartnerViewModel.swift
//  Zawaj
//
//  Created on 2025-12-22.
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth

class AddPartnerViewModel: ObservableObject {
    @Published var searchResult: User?
    @Published var isSearching: Bool = false
    @Published var requestSent: Bool = false
    @Published var error: String?

    private let firestoreService = FirestoreService()
    private let authService = AuthenticationService()

    func searchForPartner(query: String) async {
        await MainActor.run {
            isSearching = true
            error = nil
            searchResult = nil
            requestSent = false
        }

        do {
            // Search by username or email
            let user: User?

            if query.starts(with: "@") {
                // Search by username (lowercase for case-insensitive matching)
                let username = String(query.dropFirst()).lowercased()
                user = try await firestoreService.getUserByUsername(username)
            } else if query.contains("@") {
                // Search by email (lowercase for case-insensitive matching)
                user = try await firestoreService.getUserByEmail(query.lowercased())
            } else {
                // Try username without @ (lowercase for case-insensitive matching)
                user = try await firestoreService.getUserByUsername(query.lowercased())
            }

            await MainActor.run {
                if let user = user {
                    // Don't show current user in results
                    if user.id == authService.getCurrentUser()?.uid {
                        self.error = "You cannot add yourself as a partner"
                        self.searchResult = nil
                    } else {
                        self.searchResult = user
                    }
                } else {
                    self.error = "No user found with that username or email"
                }
                self.isSearching = false
            }
        } catch {
            await MainActor.run {
                self.error = "Error searching for user: \(error.localizedDescription)"
                self.isSearching = false
            }
        }
    }

    func sendPartnerRequest(to user: User) async {
        guard let currentUserId = authService.getCurrentUser()?.uid else { return }

        do {
            // Get current user info for the request
            let currentUser = try await firestoreService.getUserProfile(userId: currentUserId)

            // Check if genders are opposite
            if !currentUser.gender.isEmpty && !user.gender.isEmpty {
                if currentUser.gender.lowercased() == user.gender.lowercased() {
                    await MainActor.run {
                        self.error = "You can only partner with someone of the opposite gender"
                    }
                    return
                }
            }

            // Check if a pending request already exists from current user
            let existingOutgoingRequest = try await firestoreService.hasPendingPartnerRequest(
                from: currentUser.username,
                to: user.username
            )
            if existingOutgoingRequest {
                await MainActor.run {
                    self.error = "You already have a pending request to this user"
                }
                return
            }

            // Check if the target user has already sent a request to current user
            let existingIncomingRequest = try await firestoreService.hasPendingPartnerRequest(
                from: user.username,
                to: currentUser.username
            )
            if existingIncomingRequest {
                await MainActor.run {
                    self.error = "This user has already sent you a request. Please accept their request in the Partners tab."
                }
                return
            }

            let request = PartnerRequest(
                id: UUID().uuidString,
                senderId: currentUserId,
                senderFullName: currentUser.fullName,
                senderUsername: currentUser.username.lowercased(),
                receiverUsername: user.username.lowercased(),
                status: "pending",
                createdAt: Date(),
                respondedAt: nil
            )

            try await firestoreService.sendPartnerRequest(request: request, receiverId: user.id)

            await MainActor.run {
                self.requestSent = true
                self.error = nil
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to send request: \(error.localizedDescription)"
            }
        }
    }

    func searchAndSendRequest(query: String) async {
        await searchForPartner(query: query)

        // Only send request if user was found
        if let user = searchResult {
            await sendPartnerRequest(to: user)
        }
    }

    func clearSearch() {
        searchResult = nil
        error = nil
        requestSent = false
    }
}
