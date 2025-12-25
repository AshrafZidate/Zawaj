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

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: 0) {
                HomeTabContent(viewModel: viewModel, selectedTab: $selectedTab, selectedPartner: $selectedPartner)
            }
            
            Tab("Questions", systemImage: "questionmark.bubble", value: 1) {
                QuestionsTabContent(viewModel: viewModel)
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
            if let question = viewModel.todayQuestion {
                AnswerRevealSheet(
                    viewModel: viewModel,
                    question: question,
                    partner: partner
                )
            }
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

    var body: some View {
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

                                ForEach(viewModel.partners) { partner in
                                    PartnerCard(
                                        partner: partner,
                                        userAnswered: viewModel.userAnswered,
                                        partnerAnswered: viewModel.partnerAnswers[partner.id] ?? false,
                                        onTap: {
                                            let status = PartnerAnswerStatus.determine(
                                                userAnswered: viewModel.userAnswered,
                                                partnerAnswered: viewModel.partnerAnswers[partner.id] ?? false
                                            )

                                            if status == .reviewAnswers {
                                                selectedPartner = partner
                                            } else {
                                                selectedTab = 1
                                            }
                                        }
                                    )
                                }
                            }

                            // Show question card when user has a partner
                            TodayQuestionCard(
                                question: viewModel.todayQuestion,
                                userAnswered: viewModel.userAnswered,
                                partnerAnswered: viewModel.partnerAnswered,
                                partnerName: viewModel.partner?.fullName.split(separator: " ").first.map(String.init)
                            ) {
                                selectedTab = 1
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
    }
}

// MARK: - Questions Tab Content

struct QuestionsTabContent: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        ZStack {
            GradientBackground()

            if viewModel.hasPartner {
                QuestionsView(viewModel: viewModel)
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

#Preview {
    DashboardView()
        .environmentObject(OnboardingCoordinator())
}
