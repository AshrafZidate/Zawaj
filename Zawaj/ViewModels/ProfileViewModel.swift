//
//  ProfileViewModel.swift
//  Zawaj
//
//  Created on 2025-12-21.
//

import Foundation
import SwiftUI
import FirebaseAuth
import Combine

class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentUser: User?
    @Published var partner: User? // Kept for backward compatibility
    @Published var partners: [User] = []
    @Published var pendingPartnerRequests: [PartnerRequest] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var successMessage: String?

    // MARK: - Notification Settings
    @Published var notificationsEnabled: Bool = true
    @Published var dailyQuestionNotifications: Bool = true
    @Published var partnerAnsweredNotifications: Bool = true
    @Published var partnerRequestNotifications: Bool = true
    @Published var reminderNotifications: Bool = true

    // MARK: - App Preferences
    // User preference for how multi_choice questions are displayed:
    // .openEnded = Show as free text input
    // .multipleChoice = Show as checkbox selection
    @Published var defaultAnswerFormat: LegacyQuestionType = .openEnded

    // MARK: - Sheet States
    @Published var showingEditProfile: Bool = false
    @Published var showingChangePassword: Bool = false
    @Published var showingDeleteAccountAlert: Bool = false
    @Published var showingDisconnectPartnerAlert: Bool = false
    @Published var showingAddPartner: Bool = false
    @Published var showingSwitchAccount: Bool = false

    private let authService = AuthenticationService()
    private let firestoreService = FirestoreService()

    // MARK: - Methods

    func loadProfileData() async {
        await MainActor.run {
            isLoading = true
        }

        do {
            guard let userId = authService.getCurrentUser()?.uid else {
                throw FirestoreError.userNotFound
            }

            let user = try await firestoreService.getUserProfile(userId: userId)

            await MainActor.run {
                self.currentUser = user
            }

            // Fetch all partners
            if !user.partnerIds.isEmpty {
                var fetchedPartners: [User] = []
                for partnerId in user.partnerIds {
                    if let partnerUser = try? await firestoreService.getUserProfile(userId: partnerId) {
                        fetchedPartners.append(partnerUser)
                    }
                }
                await MainActor.run {
                    self.partners = fetchedPartners
                    self.partner = fetchedPartners.first // Keep for backward compatibility
                }
            } else if user.partnerConnectionStatus == .connected, let partnerId = user.partnerId {
                // Fallback to deprecated partnerId for backward compatibility
                let partnerUser = try? await firestoreService.getUserProfile(userId: partnerId)
                await MainActor.run {
                    self.partner = partnerUser
                    if let partnerUser = partnerUser {
                        self.partners = [partnerUser]
                    }
                }
            }

            // Fetch pending partner requests
            if !user.username.isEmpty {
                let requests = try await firestoreService.getPendingPartnerRequests(for: user.username)
                await MainActor.run {
                    self.pendingPartnerRequests = requests
                }
            }

            await MainActor.run {
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func updateProfile(updates: [String: Any]) async {
        guard let userId = currentUser?.id else { return }

        do {
            try await firestoreService.updateUserProfile(userId: userId, updates: updates)
            await loadProfileData()
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
    }

    func updateNotificationSettings() async {
        // TODO: Save notification settings to Firestore
        // For now, just update local state
    }

    func disconnectPartner(partnerId: String? = nil) async {
        guard let currentUserId = currentUser?.id else { return }

        do {
            if let partnerId = partnerId {
                // Disconnect specific partner
                try await firestoreService.disconnectPartner(currentUserId: currentUserId, partnerId: partnerId)

                await MainActor.run {
                    self.partners.removeAll { $0.id == partnerId }
                    self.currentUser?.partnerIds.removeAll { $0 == partnerId }
                    if self.partner?.id == partnerId {
                        self.partner = self.partners.first
                    }
                    self.successMessage = "Successfully separated from partner"
                }
            } else {
                // Disconnect all partners (legacy behavior)
                for partner in partners {
                    try await firestoreService.disconnectPartner(currentUserId: currentUserId, partnerId: partner.id)
                }

                await MainActor.run {
                    self.partner = nil
                    self.partners = []
                    self.currentUser?.partnerId = nil
                    self.currentUser?.partnerConnectionStatus = .none
                    self.successMessage = "Successfully separated from all partners"
                }
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
    }

    func deleteAccount(password: String) async {
        do {
            guard let userId = currentUser?.id else { return }

            // Delete from Firestore
            try await firestoreService.deleteUserProfile(userId: userId)

            // Delete from Firebase Auth
            try await authService.deleteAccount()

            await MainActor.run {
                self.successMessage = "Account deleted successfully"
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
    }

    func signOut() async {
        do {
            // Clear FCM token before signing out
            if let userId = currentUser?.id {
                NotificationService.shared.clearFCMToken(for: userId)
            }

            try authService.signOut()
            // Reset state
            await MainActor.run {
                self.currentUser = nil
                self.partner = nil
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
    }

    func changePassword(currentPassword: String, newPassword: String) async {
        await MainActor.run {
            self.error = nil
            self.isLoading = true
        }

        do {
            try await authService.updatePassword(currentPassword: currentPassword, newPassword: newPassword)
            await MainActor.run {
                self.isLoading = false
                self.successMessage = "Password changed successfully"
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.error = error.localizedDescription
            }
        }
    }

    // MARK: - Partner Requests

    func acceptPartnerRequest(_ request: PartnerRequest) async {
        guard let currentUserId = currentUser?.id else { return }

        do {
            try await firestoreService.acceptPartnerRequest(
                requestId: request.id,
                currentUserId: currentUserId,
                partnerUserId: request.senderId
            )
            await loadProfileData() // Refresh to show new partner
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
    }

    func declinePartnerRequest(_ request: PartnerRequest) async {
        do {
            try await firestoreService.rejectPartnerRequest(requestId: request.id)
            await MainActor.run {
                self.pendingPartnerRequests.removeAll { $0.id == request.id }
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
    }

    // MARK: - Developer Mode

    func switchAccount(email: String, password: String, coordinator: OnboardingCoordinator) async {
        await MainActor.run {
            self.isLoading = true
            self.error = nil
            coordinator.isSwitchingAccounts = true
        }

        do {
            // Clear FCM token for current user before signing out
            if let currentUserId = currentUser?.id {
                NotificationService.shared.clearFCMToken(for: currentUserId)
            }

            // Sign out current user
            try authService.signOut()

            // Sign in with new account
            let newUser = try await authService.signInWithEmail(email: email, password: password)

            // Load the new user's profile
            await loadProfileData()

            // Update FCM token for new user
            NotificationService.shared.updateFCMToken(for: newUser.uid)

            await MainActor.run {
                self.isLoading = false
                coordinator.isSwitchingAccounts = false
                coordinator.shouldNavigateToHome = true
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.error = error.localizedDescription
                coordinator.isSwitchingAccounts = false
            }
        }
    }
}
