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
            // Development mode: Use mock data
            if AppConfig.isDevelopmentMode {
                await loadMockData()
                return
            }

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

            // TODO: Fetch today's question from Firestore
            // For now, use placeholder data
            await MainActor.run {
                self.todayQuestion = DailyQuestion(
                    id: "placeholder",
                    questionText: "What makes you feel most loved in your relationship?",
                    questionType: .openEnded,
                    options: nil,
                    topic: "Love Languages",
                    date: Date(),
                    createdAt: Date()
                )

                // Placeholder answer status
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

    // MARK: - Mock Data for Development

    private func loadMockData() async {
        await MainActor.run {
            // Mock current user
            self.currentUser = User(
                id: AppConfig.developmentUserId,
                email: "ashraf@example.com",
                phoneNumber: "+1234567890",
                isEmailVerified: true,
                isPhoneVerified: true,
                fullName: "Ashraf Zidate",
                username: "ashraf",
                gender: "Male",
                birthday: Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date(),
                relationshipStatus: "In a relationship",
                marriageTimeline: "Within 1 year",
                topicPriorities: ["Communication", "Trust", "Intimacy"],
                partnerId: "partner_123",
                partnerConnectionStatus: .connected,
                answerPreference: "Both at same time",
                createdAt: Date(),
                updatedAt: Date(),
                photoURL: nil
            )

            // Mock partner
            self.partner = User(
                id: "partner_123",
                email: "partner@example.com",
                phoneNumber: "+1987654321",
                isEmailVerified: true,
                isPhoneVerified: true,
                fullName: "Sarah Johnson",
                username: "sarah",
                gender: "Female",
                birthday: Calendar.current.date(byAdding: .year, value: -24, to: Date()) ?? Date(),
                relationshipStatus: "In a relationship",
                marriageTimeline: "Within 1 year",
                topicPriorities: ["Communication", "Family", "Values"],
                partnerId: AppConfig.developmentUserId,
                partnerConnectionStatus: .connected,
                answerPreference: "Both at same time",
                createdAt: Date(),
                updatedAt: Date(),
                photoURL: nil
            )

            // Load question from question bank
            if let questionBank = self.questionBankService.loadQuestionBankFromJSON(),
               let randomQuestion = questionBank.questions.randomElement() {
                self.todayQuestion = DailyQuestion(
                    id: randomQuestion.id,
                    questionText: randomQuestion.questionText,
                    questionType: randomQuestion.questionType == "multipleChoice" ? .multipleChoice : .openEnded,
                    options: randomQuestion.options,
                    topic: randomQuestion.topic,
                    date: Date(),
                    createdAt: Date()
                )
            } else {
                // Fallback question if JSON fails to load
                self.todayQuestion = DailyQuestion(
                    id: "daily_1",
                    questionText: "What makes you feel most loved in your relationship?",
                    questionType: .openEnded,
                    options: nil,
                    topic: "Love Languages",
                    date: Date(),
                    createdAt: Date()
                )
            }

            // Mock answer status
            self.userAnswered = false
            self.partnerAnswered = true

            self.isLoading = false
        }
    }
}
