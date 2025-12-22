//
//  DashboardViewModel.swift
//  Zawaj
//
//  Created on 2025-12-21.
//

import Foundation
import FirebaseAuth
import Combine

class DashboardViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var partner: User?
    @Published var todayQuestion: DailyQuestion?
    @Published var userAnswered: Bool = false
    @Published var partnerAnswered: Bool = false
    @Published var isLoading: Bool = false
    @Published var error: String?

    // Sheet states
    @Published var showingAddPartner: Bool = false
    @Published var showingInvitePartner: Bool = false

    private let firestoreService = FirestoreService()
    private let authService = AuthenticationService()
    private let questionBankService = QuestionBankService()

    var hasPartner: Bool {
        currentUser?.partnerConnectionStatus == .connected
    }

    func loadDashboardData() async {
        await MainActor.run {
            isLoading = true
        }

        do {
            // Get current user ID
            guard let userId = authService.getCurrentUser()?.uid else {
                throw FirestoreError.userNotFound
            }

            // Fetch user profile
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

            // Fetch random question from Firestore
            let randomQuestion = try await questionBankService.fetchRandomQuestion()

            // TODO: Check if user and partner have answered this question
            // For now, default to not answered

            await MainActor.run {
                self.todayQuestion = randomQuestion
                self.userAnswered = false
                self.partnerAnswered = false
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }

}
