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

// MARK: - Enums

enum AppTheme: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
}

class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentUser: User?
    @Published var partner: User?
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
    @Published var streakNotifications: Bool = true

    // MARK: - App Preferences
    @Published var selectedTheme: AppTheme = .system
    @Published var defaultAnswerFormat: QuestionType = .openEnded

    // MARK: - Sheet States
    @Published var showingEditProfile: Bool = false
    @Published var showingChangePassword: Bool = false
    @Published var showingDeleteAccountAlert: Bool = false
    @Published var showingDisconnectPartnerAlert: Bool = false
    @Published var showingDebugTools: Bool = false

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

            // Fetch partner if connected
            if user.partnerConnectionStatus == .connected, let partnerId = user.partnerId {
                let partnerUser = try? await firestoreService.getUserProfile(userId: partnerId)
                await MainActor.run {
                    self.partner = partnerUser
                }
            }

            // TODO: Fetch pending partner requests

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

    func changePassword(currentPassword: String, newPassword: String) async {
        // TODO: Implement password change
    }

    func updateNotificationSettings() async {
        // TODO: Save notification settings to Firestore
        // For now, just update local state
    }

    func disconnectPartner() async {
        guard let _ = currentUser?.id else { return }

        // TODO: Implement partner disconnect logic
        await MainActor.run {
            self.partner = nil
            self.currentUser?.partnerId = nil
            self.currentUser?.partnerConnectionStatus = .none
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

    // MARK: - Mock Data for Development

}
