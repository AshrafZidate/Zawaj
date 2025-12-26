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
    // MARK: - Published Properties

    @Published var currentUser: User?
    @Published var partners: [User] = []
    @Published var selectedPartner: User?

    // Current partnership state
    @Published var currentPartnershipId: String?
    @Published var partnershipProgress: PartnershipProgress?
    @Published var todaySubtopic: Subtopic?
    @Published var todayTopic: Topic?

    // Questions for current subtopic
    @Published var questions: [Question] = []
    @Published var currentQuestionIndex: Int = 0
    @Published var userAnswers: [Int: Answer] = [:] // questionId -> Answer
    @Published var partnerAnswers: [Int: Answer] = [:] // questionId -> Answer

    // State flags
    @Published var isLoading: Bool = false
    @Published var isAllQuestionsComplete: Bool = false
    @Published var isPartnershipComplete: Bool = false
    @Published var error: String?

    // Partner requests
    @Published var pendingPartnerRequests: [PartnerRequest] = []
    @Published var showingAddPartner: Bool = false

    // MARK: - Private Properties

    private let firestoreService = FirestoreService()
    private let authService = AuthenticationService()
    private let questionBankService = QuestionBankService()

    // MARK: - Computed Properties

    var hasPartner: Bool {
        !partners.isEmpty || currentUser?.partnerConnectionStatus == .connected
    }

    var currentQuestion: Question? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }

    var progressText: String {
        guard !questions.isEmpty else { return "" }
        return "\(currentQuestionIndex + 1) of \(questions.count)"
    }

    var userGender: Gender? {
        guard let genderString = currentUser?.gender.lowercased() else { return nil }
        return Gender(rawValue: genderString)
    }

    // MARK: - Load Dashboard Data

    func loadDashboardData() async {
        await MainActor.run {
            isLoading = true
            error = nil
        }

        do {
            guard let userId = authService.getCurrentUser()?.uid else {
                throw FirestoreError.userNotFound
            }

            // Fetch user profile
            let user = try await firestoreService.getUserProfile(userId: userId)

            await MainActor.run {
                self.currentUser = user
            }

            // Fetch all partners
            var fetchedPartners: [User] = []
            if !user.partnerIds.isEmpty {
                for partnerId in user.partnerIds {
                    if let partnerUser = try? await firestoreService.getUserProfile(userId: partnerId) {
                        fetchedPartners.append(partnerUser)
                    }
                }
            }

            await MainActor.run {
                self.partners = fetchedPartners
                // Select first partner by default if none selected
                if self.selectedPartner == nil && !fetchedPartners.isEmpty {
                    self.selectedPartner = fetchedPartners.first
                }
            }

            // Load pending partner requests
            let pendingRequests = try await firestoreService.getPendingPartnerRequests(for: user.username)

            await MainActor.run {
                self.pendingPartnerRequests = pendingRequests
            }

            // If we have a selected partner, load the partnership data
            if let partner = selectedPartner {
                await loadPartnershipData(for: partner)
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

    // MARK: - Partnership Data

    func selectPartner(_ partner: User) async {
        await MainActor.run {
            self.selectedPartner = partner
            self.isLoading = true
        }

        await loadPartnershipData(for: partner)

        await MainActor.run {
            self.isLoading = false
        }
    }

    private func loadPartnershipData(for partner: User) async {
        guard let user = currentUser else { return }

        do {
            // Create partnership ID (MaleId-FemaleId)
            let partnershipId = createPartnershipId(user: user, partner: partner)

            await MainActor.run {
                self.currentPartnershipId = partnershipId
            }

            // Calculate combined topic order
            let combinedOrder = try await questionBankService.calculateCombinedTopicOrder(
                userAPriorities: user.topicPriorities,
                userBPriorities: partner.topicPriorities
            )

            // Get or create partnership progress
            let progress = try await firestoreService.getOrCreatePartnershipProgress(
                partnershipId: partnershipId,
                userIds: [user.id, partner.id],
                combinedTopicOrder: combinedOrder
            )

            await MainActor.run {
                self.partnershipProgress = progress
                self.isPartnershipComplete = progress.isComplete
            }

            // If partnership is complete, no more questions
            if progress.isComplete {
                await MainActor.run {
                    self.todaySubtopic = nil
                    self.todayTopic = nil
                    self.questions = []
                }
                return
            }

            // Get or create today's subtopic assignment
            await loadTodaySubtopic(partnershipId: partnershipId, progress: progress)

        } catch {
            await MainActor.run {
                self.error = "Failed to load partnership: \(error.localizedDescription)"
            }
        }
    }

    private func loadTodaySubtopic(partnershipId: String, progress: PartnershipProgress) async {
        do {
            // Check if we already have an assignment for today
            var assignment = try await firestoreService.getTodaySubtopicAssignment(partnershipId: partnershipId)

            if assignment == nil {
                // Need to create a new assignment
                var mutableProgress = progress

                // Try to get the next subtopic
                var nextSubtopic = try await questionBankService.getNextSubtopic(progress: mutableProgress)

                // If nil, might need to increment round
                while nextSubtopic == nil && !mutableProgress.isComplete {
                    // Check if there are more rounds
                    let maxRound = try await getMaxSubtopicCount(for: mutableProgress.combinedTopicOrder)

                    if mutableProgress.currentRound < maxRound {
                        // Increment round
                        mutableProgress.currentRound += 1
                        try await firestoreService.incrementPartnershipRound(partnershipId: partnershipId)
                        nextSubtopic = try await questionBankService.getNextSubtopic(progress: mutableProgress)
                    } else {
                        // All complete
                        mutableProgress.isComplete = true
                        try await firestoreService.markPartnershipComplete(partnershipId: partnershipId)

                        await MainActor.run {
                            self.partnershipProgress = mutableProgress
                            self.isPartnershipComplete = true
                            self.todaySubtopic = nil
                            self.todayTopic = nil
                            self.questions = []
                        }
                        return
                    }
                }

                guard let subtopic = nextSubtopic else {
                    // No more subtopics
                    await MainActor.run {
                        self.isPartnershipComplete = true
                    }
                    return
                }

                // Create assignment for today
                assignment = try await firestoreService.createDailySubtopicAssignment(
                    partnershipId: partnershipId,
                    subtopicId: subtopic.id
                )
            }

            guard let todayAssignment = assignment else { return }

            // Fetch the subtopic
            guard let subtopic = try await questionBankService.fetchSubtopic(id: todayAssignment.subtopicId) else {
                throw FirestoreError.invalidData
            }

            // Fetch the topic
            let topic = try await questionBankService.fetchTopic(id: subtopic.topicId)

            await MainActor.run {
                self.todaySubtopic = subtopic
                self.todayTopic = topic
            }

            // Load questions for this subtopic
            await loadQuestionsForSubtopic(subtopic, partnershipId: partnershipId)

        } catch {
            await MainActor.run {
                self.error = "Failed to load today's questions: \(error.localizedDescription)"
            }
        }
    }

    private func loadQuestionsForSubtopic(_ subtopic: Subtopic, partnershipId: String) async {
        guard let user = currentUser, let partner = selectedPartner else { return }

        do {
            // Fetch all questions for this subtopic, filtered by user's gender
            let allQuestions = try await questionBankService.fetchQuestions(
                forSubtopicId: subtopic.id,
                gender: userGender
            )

            let questionIds = allQuestions.map { $0.id }

            // Fetch user's existing answers for this subtopic
            let existingUserAnswers = try await firestoreService.getAnswersForSubtopic(
                userId: user.id,
                subtopicId: subtopic.id,
                questionIds: questionIds
            )

            // Fetch partner's existing answers
            let existingPartnerAnswers = try await firestoreService.getAnswersForSubtopic(
                userId: partner.id,
                subtopicId: subtopic.id,
                questionIds: questionIds
            )

            // Filter questions based on branching conditions
            let filteredQuestions = questionBankService.filterQuestionsForDisplay(
                questions: allQuestions,
                previousAnswers: existingUserAnswers,
                userGender: userGender
            )

            // Find the first unanswered question
            var startIndex = 0
            for (index, question) in filteredQuestions.enumerated() {
                if existingUserAnswers[question.id] == nil {
                    startIndex = index
                    break
                }
                // If all are answered, start at the end (completion state)
                if index == filteredQuestions.count - 1 {
                    startIndex = filteredQuestions.count
                }
            }

            await MainActor.run {
                self.questions = filteredQuestions
                self.userAnswers = existingUserAnswers
                self.partnerAnswers = existingPartnerAnswers
                self.currentQuestionIndex = startIndex
                self.isAllQuestionsComplete = startIndex >= filteredQuestions.count
            }

        } catch {
            await MainActor.run {
                self.error = "Failed to load questions: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Answer Submission

    func submitAnswer(answerText: String, selectedOptions: [String]? = nil) async {
        guard let user = currentUser,
              let partnershipId = currentPartnershipId,
              let question = currentQuestion else { return }

        await MainActor.run {
            self.error = nil
        }

        do {
            // Submit the answer
            try await firestoreService.submitAnswer(
                userId: user.id,
                questionId: question.id,
                partnershipId: partnershipId,
                answerText: answerText,
                selectedOptions: selectedOptions
            )

            // Create local Answer object for state update
            let answer = Answer(
                id: Answer.createDocumentId(userId: user.id, questionId: question.id).hashValue,
                userId: user.id,
                questionId: question.id,
                partnershipId: partnershipId,
                answerText: answerText,
                selectedOptions: selectedOptions
            )

            await MainActor.run {
                self.userAnswers[question.id] = answer
            }

            // Re-filter questions in case branching conditions changed
            await refilterQuestionsAfterAnswer()

            // Move to next question
            await moveToNextQuestion()

        } catch {
            await MainActor.run {
                self.error = "Failed to submit answer: \(error.localizedDescription)"
            }
        }
    }

    private func refilterQuestionsAfterAnswer() async {
        guard let subtopic = todaySubtopic else { return }

        do {
            let allQuestions = try await questionBankService.fetchQuestions(
                forSubtopicId: subtopic.id,
                gender: userGender
            )

            let filteredQuestions = questionBankService.filterQuestionsForDisplay(
                questions: allQuestions,
                previousAnswers: userAnswers,
                userGender: userGender
            )

            await MainActor.run {
                self.questions = filteredQuestions
            }
        } catch {
            // If refiltering fails, continue with current questions
        }
    }

    private func moveToNextQuestion() async {
        await MainActor.run {
            // Find next unanswered question
            var nextIndex = self.currentQuestionIndex + 1

            while nextIndex < self.questions.count {
                let question = self.questions[nextIndex]
                if self.userAnswers[question.id] == nil {
                    break
                }
                nextIndex += 1
            }

            if nextIndex >= self.questions.count {
                // All questions answered for today
                self.isAllQuestionsComplete = true
                self.currentQuestionIndex = self.questions.count
            } else {
                self.currentQuestionIndex = nextIndex
            }
        }

        // Check if subtopic is complete for both partners
        await checkSubtopicCompletion()
    }

    private func checkSubtopicCompletion() async {
        guard let subtopic = todaySubtopic,
              let partnershipId = currentPartnershipId,
              let partner = selectedPartner,
              let user = currentUser else { return }

        do {
            let questionIds = questions.map { $0.id }

            let bothComplete = try await firestoreService.haveBothPartnersCompletedSubtopic(
                partnerIds: [user.id, partner.id],
                questionIds: questionIds
            )

            if bothComplete {
                // Mark subtopic as completed
                try await firestoreService.markSubtopicCompleted(
                    partnershipId: partnershipId,
                    subtopicId: subtopic.id
                )

                // Update local progress
                await MainActor.run {
                    self.partnershipProgress?.completedSubtopics.append(subtopic.id)
                }
            }
        } catch {
            // Non-critical error, don't show to user
        }
    }

    // MARK: - Navigation

    func goToPreviousQuestion() {
        guard currentQuestionIndex > 0 else { return }
        currentQuestionIndex -= 1
    }

    func goToNextQuestion() {
        guard currentQuestionIndex < questions.count - 1 else { return }
        currentQuestionIndex += 1
    }

    // MARK: - Partner Requests

    func loadPendingPartnerRequests() async {
        guard let username = currentUser?.username else { return }

        do {
            let requests = try await firestoreService.getPendingPartnerRequests(for: username)
            await MainActor.run {
                self.pendingPartnerRequests = requests
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to load partner requests: \(error.localizedDescription)"
            }
        }
    }

    func acceptPartnerRequest(_ request: PartnerRequest) async {
        guard let userId = authService.getCurrentUser()?.uid else { return }

        do {
            try await firestoreService.acceptPartnerRequest(
                requestId: request.id,
                currentUserId: userId,
                partnerUserId: request.senderId
            )

            await MainActor.run {
                self.pendingPartnerRequests.removeAll { $0.id == request.id }
            }

            await loadDashboardData()
        } catch {
            await MainActor.run {
                self.error = "Failed to accept request: \(error.localizedDescription)"
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
                self.error = "Failed to decline request: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Helper Methods

    private func createPartnershipId(user: User, partner: User) -> String {
        // Partnership ID format: MaleId-FemaleId
        let userIsMale = user.gender.lowercased() == "male"
        let maleId = userIsMale ? user.id : partner.id
        let femaleId = userIsMale ? partner.id : user.id
        return PartnershipProgress.createPartnershipId(maleId: maleId, femaleId: femaleId)
    }

    private func getMaxSubtopicCount(for topicIds: [Int]) async throws -> Int {
        var maxCount = 0
        for topicId in topicIds {
            let subtopics = try await questionBankService.fetchSubtopics(forTopicId: topicId)
            maxCount = max(maxCount, subtopics.count)
        }
        return maxCount
    }

    // MARK: - Refresh

    func refreshPartnerAnswers() async {
        guard let partner = selectedPartner,
              let subtopic = todaySubtopic else { return }

        do {
            let questionIds = questions.map { $0.id }
            let partnerAnswersDict = try await firestoreService.getAnswersForSubtopic(
                userId: partner.id,
                subtopicId: subtopic.id,
                questionIds: questionIds
            )

            await MainActor.run {
                self.partnerAnswers = partnerAnswersDict
            }
        } catch {
            // Silent fail for refresh
        }
    }
}
