//
//  DashboardView.swift
//  Zawaj
//
//  Created on 2025-12-21.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator
    @StateObject private var viewModel = DashboardViewModel()
    @State private var selectedTab: Int = 0
    @State private var selectedPartner: User?
    @State private var selectedPartnerForQuestions: User?

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: 0) {
                HomeTabContent(viewModel: viewModel, selectedTab: $selectedTab, selectedPartner: $selectedPartner, selectedPartnerForQuestions: $selectedPartnerForQuestions)
            }

            Tab("Questions", systemImage: "questionmark.bubble", value: 1) {
                QuestionsTabContent(viewModel: viewModel, selectedPartnerForQuestions: $selectedPartnerForQuestions)
            }
            
            Tab("Archives", systemImage: "archivebox", value: 2) {
                HistoryTabContent(viewModel: viewModel)
            }
            
            Tab("Preferences", systemImage: "gearshape", value: 3) {
                ProfileTabContent()
            }
        }
        .tint(Color(red: 0.94, green: 0.26, blue: 0.42))
        .sheet(isPresented: $viewModel.showingAddPartner) {
            AddPartnerView()
        }
        .sheet(item: $selectedPartner) { partner in
            // Show answers review sheet for selected partner
            // The QuestionsView handles this via AnswersReviewSheet
            AnswersReviewSheetWrapper(viewModel: viewModel, partner: partner)
        }
        .onAppear {
            Task {
                await viewModel.loadDashboardData()
            }
        }
        .onChange(of: selectedTab) { oldTab, newTab in
            // Reload dashboard data when switching away from Preferences tab
            // to sync any changes made there (e.g., accepting/declining partner requests)
            if oldTab == 3 && newTab != 3 {
                Task {
                    await viewModel.loadDashboardData()
                }
            }
        }
        .onChange(of: coordinator.shouldNavigateToHome) { _, shouldNavigate in
            if shouldNavigate {
                selectedTab = 0
                coordinator.shouldNavigateToHome = false
                Task {
                    await viewModel.loadDashboardData()
                }
            }
        }
    }
}

// MARK: - Home Tab Content

struct HomeTabContent: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Binding var selectedTab: Int
    @Binding var selectedPartner: User?
    @Binding var selectedPartnerForQuestions: User?

    // Share content for invite
    private let inviteMessage = "Download the Zawaj app so we can get to know each other better for marriage!"
    private let appStoreLink = "https://apps.apple.com/app/zawaj" // TODO: Replace with actual App Store link

    private var shareContent: String {
        return "\(inviteMessage)\n\n\(appStoreLink)"
    }

    // Sort partners - for now, maintain original order
    // Future: Could sort by answer status per partnership
    private var sortedPartners: [User] {
        viewModel.partners
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()

                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Always show pending partner requests at the top if there are any
                            if !viewModel.pendingPartnerRequests.isEmpty {
                                PendingRequestsSection(
                                    requests: viewModel.pendingPartnerRequests,
                                    onAccept: { request in
                                        Task { await viewModel.acceptPartnerRequest(request) }
                                    },
                                    onDecline: { request in
                                        Task { await viewModel.declinePartnerRequest(request) }
                                    }
                                )
                            }

                            if viewModel.hasPartner {
                                // Partners Section
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Your Partners")
                                        .font(.title2.weight(.bold))
                                        .foregroundColor(.white)

                                    ForEach(sortedPartners) { partner in
                                        PartnerCardNew(
                                            partner: partner,
                                            viewModel: viewModel,
                                            onTap: {
                                                // Navigate to questions tab and select this partner
                                                Task {
                                                    await viewModel.selectPartner(partner)
                                                }
                                                selectedPartnerForQuestions = partner
                                                selectedTab = 1
                                            },
                                            onReview: {
                                                // Show review sheet
                                                Task {
                                                    await viewModel.selectPartner(partner)
                                                }
                                                selectedPartner = partner
                                            }
                                        )
                                    }
                                }
                            } else {
                                NoPartnerView(
                                    pendingRequests: [], // Requests already shown above
                                    onAddPartner: {
                                        viewModel.showingAddPartner = true
                                    },
                                    onAcceptRequest: { _ in },
                                    onDeclineRequest: { _ in }
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
            
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .toolbar {
                if viewModel.hasPartner {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        ShareLink(item: shareContent) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.white)
                        }

                        Button {
                            viewModel.showingAddPartner = true
                        } label: {
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .navigationTitle("Zawāj")
            .toolbarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Questions Tab Content

struct QuestionsTabContent: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Binding var selectedPartnerForQuestions: User?

    var body: some View {
        ZStack {
            GradientBackground()

            if viewModel.hasPartner {
                QuestionsView(viewModel: viewModel, selectedPartnerForQuestions: $selectedPartnerForQuestions)
            } else {
                NoPartnerView(
                    pendingRequests: viewModel.pendingPartnerRequests,
                    onAddPartner: {
                        viewModel.showingAddPartner = true
                    },
                    onAcceptRequest: { request in
                        Task { await viewModel.acceptPartnerRequest(request) }
                    },
                    onDeclineRequest: { request in
                        Task { await viewModel.declinePartnerRequest(request) }
                    }
                )
                .padding(.horizontal, 24)
            }
        }
    }
}

// MARK: - Archives Tab Content

struct HistoryTabContent: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        ZStack {
            GradientBackground()

            if viewModel.hasPartner {
                PlaceholderView(icon: "archivebox", title: "Archives", message: "Your past answers will appear here")
            } else {
                NoPartnerView(
                    pendingRequests: viewModel.pendingPartnerRequests,
                    onAddPartner: {
                        viewModel.showingAddPartner = true
                    },
                    onAcceptRequest: { request in
                        Task { await viewModel.acceptPartnerRequest(request) }
                    },
                    onDeclineRequest: { request in
                        Task { await viewModel.declinePartnerRequest(request) }
                    }
                )
                .padding(.horizontal, 24)
            }
        }
    }
}

// MARK: - Pending Requests Section

struct PendingRequestsSection: View {
    let requests: [PartnerRequest]
    let onAccept: (PartnerRequest) -> Void
    let onDecline: (PartnerRequest) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Partner Requests")
                .font(.title2.weight(.bold))
                .foregroundColor(.white)

            ForEach(requests) { request in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(request.senderDisplayName)
                            .font(.body.weight(.medium))
                            .foregroundColor(.white)

                        Text("@\(request.senderUsername)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Button {
                            onAccept(request)
                        } label: {
                            Image(systemName: "checkmark")
                                .font(.body.weight(.semibold))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(.green)

                        Button {
                            onDecline(request)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.body.weight(.semibold))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(.red)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .glassEffect(.clear)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Profile Tab Content

struct ProfileTabContent: View {
    var body: some View {
        ZStack {
            GradientBackground()
            ProfileView()
        }
    }
}

// MARK: - Partner Card (New)

struct PartnerCardNew: View {
    let partner: User
    @ObservedObject var viewModel: DashboardViewModel
    let onTap: () -> Void
    let onReview: () -> Void

    private var isSelectedPartner: Bool {
        viewModel.selectedPartner?.id == partner.id
    }

    private var topicName: String? {
        guard isSelectedPartner else { return nil }
        return viewModel.todayTopic?.name
    }

    private var status: PartnerAnswerStatus {
        guard isSelectedPartner else { return .answerBoth }

        if viewModel.isPartnershipComplete {
            return .newQuestionsTomorrow
        }

        let allUserAnswered = viewModel.isAllQuestionsComplete
        let allPartnerAnswered = !viewModel.questions.isEmpty && viewModel.questions.allSatisfy { question in
            viewModel.partnerAnswers[question.id] != nil
        }

        return PartnerAnswerStatus.determine(userAnswered: allUserAnswered, partnerAnswered: allPartnerAnswered)
    }

    private var topicText: String {
        guard let topic = topicName else {
            return "Tap to see today's questions"
        }

        switch status {
        case .reviewAnswers, .newQuestionsTomorrow:
            return "Today's topic was \(topic)"
        default:
            return "Today's topic is \(topic)"
        }
    }

    var body: some View {
        Button(action: {
            if status == .reviewAnswers {
                onReview()
            } else {
                onTap()
            }
        }) {
            HStack {
                // Partner Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(partner.fullName)
                        .font(.body.weight(.medium))
                        .foregroundColor(.white)

                    Text(topicText)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                // Status indicator
                HStack(spacing: 6) {
                    Image(systemName: status.icon)
                        .font(.system(size: 18))
                        .foregroundColor(status.iconColor)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .glassEffect(.clear)
        }
        .buttonStyle(PartnerCardButtonStyle())
        .onAppear {
            // Load partnership data if this is the first/only partner
            if viewModel.selectedPartner == nil {
                Task {
                    await viewModel.selectPartner(partner)
                }
            }
        }
    }
}

// MARK: - Answers Review Sheet Wrapper

struct AnswersReviewSheetWrapper: View {
    @ObservedObject var viewModel: DashboardViewModel
    let partner: User
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()

                if viewModel.questions.isEmpty {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))

                        Text("Loading answers...")
                            .foregroundColor(.white.opacity(0.7))
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Header
                            VStack(spacing: 8) {
                                if let topic = viewModel.todayTopic {
                                    Text(topic.name)
                                        .font(.title2.weight(.bold))
                                        .foregroundColor(.white)
                                }

                                if let subtopic = viewModel.todaySubtopic {
                                    Text(subtopic.name)
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                            .padding(.top, 8)

                            // Questions and Answers
                            ForEach(viewModel.questions) { question in
                                AnswerComparisonCardDashboard(
                                    question: question,
                                    userAnswer: viewModel.userAnswers[question.id],
                                    partnerAnswer: viewModel.partnerAnswers[question.id],
                                    partnerName: partner.fullName.split(separator: " ").first.map(String.init) ?? "Partner"
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Compare Answers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            // Refresh partner answers when sheet appears
            Task {
                await viewModel.refreshPartnerAnswers()
            }
        }
    }
}

// MARK: - Answer Comparison Card (Dashboard)

struct AnswerComparisonCardDashboard: View {
    let question: Question
    let userAnswer: Answer?
    let partnerAnswer: Answer?
    let partnerName: String

    private var answersMatch: Bool {
        guard let userText = userAnswer?.answerText,
              let partnerText = partnerAnswer?.answerText else {
            return false
        }
        return userText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ==
               partnerText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Question
            Text(question.questionText)
                .font(.headline)
                .foregroundColor(.white)

            // Your Answer
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(Color(red: 0.94, green: 0.26, blue: 0.42))
                    Text("Your Answer")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white.opacity(0.8))
                }

                if let answer = userAnswer {
                    Text(answer.answerText)
                        .font(.body)
                        .foregroundColor(.white)
                } else {
                    Text("Not answered yet")
                        .font(.body)
                        .italic()
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            // Partner's Answer
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "person.circle")
                        .foregroundColor(.blue)
                    Text("\(partnerName)'s Answer")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white.opacity(0.8))
                }

                if let answer = partnerAnswer {
                    Text(answer.answerText)
                        .font(.body)
                        .foregroundColor(.white)
                } else {
                    Text("Waiting for answer...")
                        .font(.body)
                        .italic()
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            // Match indicator (for choice questions with options)
            if (question.questionType == .singleChoice || question.questionType == .openEnded) &&
               question.options != nil && userAnswer != nil && partnerAnswer != nil {
                HStack(spacing: 8) {
                    Image(systemName: answersMatch ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(answersMatch ? .green : .orange)

                    Text(answersMatch ? "You both chose the same!" : "Different choices - discuss together")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    DashboardView()
        .environmentObject(OnboardingCoordinator())
}
