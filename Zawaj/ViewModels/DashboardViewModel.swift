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
    @Published var currentAssignment: DailySubtopicAssignment?
    @Published var todaySubtopic: Subtopic?
    @Published var todayTopic: Topic?

    // Questions for current subtopic
    @Published var questions: [Question] = []  // Filtered questions for current user's flow
    @Published var allSubtopicQuestions: [Question] = []  // All questions (unfiltered) for answer review
    @Published var currentQuestionIndex: Int = 0
    @Published var userAnswers: [Int: Answer] = [:] // questionId -> Answer
    @Published var partnerAnswers: [Int: Answer] = [:] // questionId -> Answer

    // State flags
    @Published var isLoading: Bool = false
    @Published var isAllQuestionsComplete: Bool = false
    @Published var isPartnershipComplete: Bool = false
    @Published var isWaitingForNextDay: Bool = false  // Both completed, waiting for 12pm GMT
    @Published var timeUntilNextSubtopic: TimeInterval = 0
    @Published var error: String?

    // Remind partner state
    @Published var canRemindPartner: Bool = true
    @Published var reminderCooldownMinutes: Int = 0
    @Published var isRemindingPartner: Bool = false
    @Published var reminderSuccessMessage: String?

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
        // Cap the display index at questions.count to avoid showing "N+1 of N" when complete
        let displayIndex = min(currentQuestionIndex + 1, questions.count)
        return "\(displayIndex) of \(questions.count)"
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
            // Get active assignment (today's or most recent incomplete)
            // Cloud Functions handle creating new assignments at 12pm GMT
            let assignment = try await firestoreService.getActiveSubtopicAssignment(partnershipId: partnershipId)

            guard let activeAssignment = assignment else {
                // No assignment exists - this means:
                // 1. Partnership just formed (Cloud Function will create first assignment)
                // 2. Both completed previous assignment but 12pm GMT hasn't passed yet
                // Check if there's a completed assignment waiting for next day
                let todayAssignment = try await firestoreService.getTodaySubtopicAssignment(partnershipId: partnershipId)

                if let completed = todayAssignment, completed.bothCompleted {
                    // Waiting for next assignment at 12pm GMT
                    let timeRemaining = firestoreService.getTimeUntilNext12pmGMT()
                    await MainActor.run {
                        self.isWaitingForNextDay = true
                        self.timeUntilNextSubtopic = timeRemaining
                        self.todaySubtopic = nil
                        self.todayTopic = nil
                        self.questions = []
                    }
                    return
                }

                // No assignment at all - waiting for Cloud Function to create first one
                await MainActor.run {
                    self.isWaitingForNextDay = false
                    self.todaySubtopic = nil
                    self.todayTopic = nil
                    self.questions = []
                }
                return
            }

            // Check if both have completed this assignment
            if activeAssignment.bothCompleted {
                // Check if next assignment should be available
                let today = DailySubtopicAssignment.todayDateString()
                if let nextDate = activeAssignment.nextScheduledDate, nextDate <= today {
                    // Should have a new assignment - try to fetch it
                    if let newAssignment = try await firestoreService.getTodaySubtopicAssignment(partnershipId: partnershipId),
                       !newAssignment.bothCompleted {
                        // Use the new assignment
                        await loadAssignment(newAssignment, partnershipId: partnershipId)
                        return
                    }
                }

                // Still waiting for 12pm GMT
                let timeRemaining = firestoreService.getTimeUntilNext12pmGMT()
                await MainActor.run {
                    self.isWaitingForNextDay = true
                    self.timeUntilNextSubtopic = timeRemaining
                    self.currentAssignment = activeAssignment
                }

                // Still load the subtopic info for display
                if let subtopic = try await questionBankService.fetchSubtopic(id: activeAssignment.subtopicId) {
                    let topic = try await questionBankService.fetchTopic(id: subtopic.topicId)
                    await MainActor.run {
                        self.todaySubtopic = subtopic
                        self.todayTopic = topic
                    }
                }
                return
            }

            // Load the active assignment
            await loadAssignment(activeAssignment, partnershipId: partnershipId)

        } catch {
            await MainActor.run {
                self.error = "Failed to load today's questions: \(error.localizedDescription)"
            }
        }
    }

    private func loadAssignment(_ assignment: DailySubtopicAssignment, partnershipId: String) async {
        do {
            // Fetch the subtopic
            guard let subtopic = try await questionBankService.fetchSubtopic(id: assignment.subtopicId) else {
                throw FirestoreError.invalidData
            }

            // Fetch the topic
            let topic = try await questionBankService.fetchTopic(id: subtopic.topicId)

            await MainActor.run {
                self.currentAssignment = assignment
                self.todaySubtopic = subtopic
                self.todayTopic = topic
                self.isWaitingForNextDay = false
            }

            // Load questions for this subtopic
            await loadQuestionsForSubtopic(subtopic, partnershipId: partnershipId)

        } catch {
            await MainActor.run {
                self.error = "Failed to load assignment: \(error.localizedDescription)"
            }
        }
    }

    private func loadQuestionsForSubtopic(_ subtopic: Subtopic, partnershipId: String) async {
        guard let user = currentUser, let partner = selectedPartner else { return }

        do {
            // Fetch ALL questions for this subtopic (not gender-filtered) for answer review
            let allQuestionsUnfiltered = try await questionBankService.fetchQuestions(forSubtopicId: subtopic.id)
            let allQuestionIds = allQuestionsUnfiltered.map { $0.id }

            // Fetch all questions for this subtopic, filtered by user's gender
            let allQuestions = try await questionBankService.fetchQuestions(
                forSubtopicId: subtopic.id,
                gender: userGender
            )

            // Fetch user's existing answers for this subtopic (for all questions)
            let existingUserAnswers = try await firestoreService.getAnswersForSubtopic(
                userId: user.id,
                subtopicId: subtopic.id,
                questionIds: allQuestionIds
            )

            // Fetch partner's existing answers (for all questions, to show in review)
            let existingPartnerAnswers = try await firestoreService.getAnswersForSubtopic(
                userId: partner.id,
                subtopicId: subtopic.id,
                questionIds: allQuestionIds
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
                self.allSubtopicQuestions = allQuestionsUnfiltered  // Store all questions (unfiltered) for answer review
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
              let user = currentUser,
              let assignment = currentAssignment else { return }

        do {
            let questionIds = questions.map { $0.id }

            // Check if current user has completed all their questions
            let userComplete = questionIds.allSatisfy { userAnswers[$0] != nil }

            if userComplete {
                // Mark this user as completed for the assignment
                try await firestoreService.markUserCompletedSubtopic(
                    partnershipId: partnershipId,
                    date: assignment.date,
                    userId: user.id
                )

                // Check if both users are now complete
                // The Cloud Function will handle updating both_completed and scheduling
                let bothComplete = try await firestoreService.checkIfBothCompleted(
                    partnershipId: partnershipId,
                    date: assignment.date,
                    userIds: [user.id, partner.id]
                )

                if bothComplete {
                    // Cloud Function handles marking subtopic as completed
                    // Just update local state to show waiting UI
                    let timeRemaining = firestoreService.getTimeUntilNext12pmGMT()
                    await MainActor.run {
                        if !self.partnershipProgress!.completedSubtopics.contains(subtopic.id) {
                            self.partnershipProgress?.completedSubtopics.append(subtopic.id)
                        }
                        self.isWaitingForNextDay = true
                        self.timeUntilNextSubtopic = timeRemaining
                    }
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

    // MARK: - Remind Partner

    /// Check if user can send a reminder to their partner
    func checkReminderCooldown() async {
        guard let userId = currentUser?.id,
              let partnershipId = currentPartnershipId else {
            return
        }

        do {
            let (canSend, remainingMinutes) = try await firestoreService.canSendReminder(
                userId: userId,
                partnershipId: partnershipId
            )

            await MainActor.run {
                self.canRemindPartner = canSend
                self.reminderCooldownMinutes = remainingMinutes
            }
        } catch {
            // If check fails, assume can send
            await MainActor.run {
                self.canRemindPartner = true
                self.reminderCooldownMinutes = 0
            }
        }
    }

    /// Send a reminder notification to the partner
    func remindPartner() async {
        guard let partnershipId = currentPartnershipId,
              let partnerId = selectedPartner?.id else {
            return
        }

        await MainActor.run {
            self.isRemindingPartner = true
            self.error = nil
            self.reminderSuccessMessage = nil
        }

        do {
            let message = try await firestoreService.remindPartner(
                partnershipId: partnershipId,
                partnerId: partnerId
            )

            await MainActor.run {
                self.isRemindingPartner = false
                self.reminderSuccessMessage = message
                self.canRemindPartner = false
                self.reminderCooldownMinutes = 240 // 4 hours
            }
        } catch {
            await MainActor.run {
                self.isRemindingPartner = false
                self.error = error.localizedDescription
            }
        }
    }
}
