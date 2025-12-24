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
    @Published var partners: [User] = []
    @Published var partner: User? // Deprecated: kept for backward compatibility
    @Published var todayQuestion: DailyQuestion?
    @Published var userAnswered: Bool = false
    @Published var partnerAnswers: [String: Bool] = [:] // partnerId -> answered status
    @Published var partnerAnswered: Bool = false // Deprecated: kept for backward compatibility
    @Published var isLoading: Bool = false
    @Published var error: String?

    // Sheet states
    @Published var showingAddPartner: Bool = false
    @Published var showingInvitePartner: Bool = false

    private let firestoreService = FirestoreService()
    private let authService = AuthenticationService()
    private let questionBankService = QuestionBankService()

    var hasPartner: Bool {
        !partners.isEmpty || currentUser?.partnerConnectionStatus == .connected
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

            // Fetch all partners if user has partnerIds
            var fetchedPartners: [User] = []
            if !user.partnerIds.isEmpty {
                for partnerId in user.partnerIds {
                    if let partnerUser = try? await firestoreService.getUserProfile(userId: partnerId) {
                        fetchedPartners.append(partnerUser)
                    }
                }
            }
            // Backward compatibility: also check single partnerId
            else if user.partnerConnectionStatus == .connected, let partnerId = user.partnerId {
                if let partnerUser = try? await firestoreService.getUserProfile(userId: partnerId) {
                    fetchedPartners.append(partnerUser)
                    await MainActor.run {
                        self.partner = partnerUser
                    }
                }
            }

            await MainActor.run {
                self.partners = fetchedPartners
            }

            // Fetch random question from Firestore
            let question = try await questionBankService.fetchRandomQuestion()

            // Check if user and partners have answered this question
            var answersDict: [String: Bool] = [:]

            // Check if current user has answered
            let userHasAnswered = try await firestoreService.hasUserAnswered(userId: userId, questionId: question.id)

            // Check each partner's answer status
            for partner in fetchedPartners {
                let partnerHasAnswered = try await firestoreService.hasUserAnswered(userId: partner.id, questionId: question.id)
                answersDict[partner.id] = partnerHasAnswered
            }

            await MainActor.run {
                self.todayQuestion = question
                self.userAnswered = userHasAnswered
                self.partnerAnswers = answersDict
                self.partnerAnswered = answersDict.values.contains(true) // Backward compatibility
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func submitAnswer(questionId: String, answerText: String) async {
        await MainActor.run {
            self.error = nil
        }

        do {
            guard let userId = authService.getCurrentUser()?.uid else {
                throw FirestoreError.userNotFound
            }

            let answer = Answer(
                userId: userId,
                questionId: questionId,
                answerText: answerText
            )

            try await firestoreService.submitAnswer(answer)

            // Update local state
            await MainActor.run {
                self.userAnswered = true
            }

            // Reload dashboard to get latest answer status
            await loadDashboardData()
        } catch {
            await MainActor.run {
                self.error = "Failed to submit answer: \(error.localizedDescription)"
            }
        }
    }

    func getAnswers(for questionId: String) async -> (userAnswer: String?, partnerAnswers: [String: String]) {
        guard let userId = authService.getCurrentUser()?.uid else {
            return (nil, [:])
        }

        do {
            // Get user's answer
            let userAnswer = try await firestoreService.getAnswer(userId: userId, questionId: questionId)

            // Get all partners' answers
            let partnerIds = partners.map { $0.id }
            let answers = try await firestoreService.getUserAnswersForQuestion(questionId: questionId, userIds: partnerIds)

            var partnerAnswersDict: [String: String] = [:]
            for (partnerId, answer) in answers {
                partnerAnswersDict[partnerId] = answer.answerText
            }

            return (userAnswer?.answerText, partnerAnswersDict)
        } catch {
            await MainActor.run {
                self.error = "Failed to fetch answers: \(error.localizedDescription)"
            }
            return (nil, [:])
        }
    }

}
