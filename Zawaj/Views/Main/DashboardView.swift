//
//  DashboardView.swift
//  Zawaj
//
//  Created on 2025-12-21.
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var selectedTab: Int = 0

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.18, green: 0.05, blue: 0.35), // #2e0d5a
                    Color(red: 0.72, green: 0.28, blue: 0.44)  // #b7486f
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Content based on selected tab
            Group {
                switch selectedTab {
                case 0:
                    // Home Tab
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    } else {
                        ScrollView {
                            VStack(spacing: 24) {
                                HeaderView(userName: viewModel.currentUser?.fullName.split(separator: " ").first.map(String.init))
                                    .padding(.top, 16)

                                if viewModel.hasPartner {
                                    // Show question card when user has a partner
                                    TodayQuestionCard(
                                        question: viewModel.todayQuestion,
                                        userAnswered: viewModel.userAnswered,
                                        partnerAnswered: viewModel.partnerAnswered,
                                        partnerName: viewModel.partner?.fullName.split(separator: " ").first.map(String.init)
                                    ) {
                                        // TODO: Navigate to question detail screen
                                    }

                                    PartnerStatusCard(partner: viewModel.partner)
                                } else {
                                    // Show no-partner state
                                    NoPartnerView(
                                        onAddPartner: {
                                            viewModel.showingAddPartner = true
                                        },
                                        onInvitePartner: {
                                            viewModel.showingInvitePartner = true
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 100)
                        }
                    }
                case 1:
                    // Questions Tab - Placeholder
                    PlaceholderView(icon: "questionmark.bubble", title: "Questions", message: "Daily questions will appear here")
                case 2:
                    // History Tab - Placeholder
                    PlaceholderView(icon: "clock.arrow.circlepath", title: "History", message: "Your answer history will appear here")
                case 3:
                    // Profile Tab
                    ProfileView()
                default:
                    EmptyView()
                }
            }

            // Error alert
            if let error = viewModel.error {
                VStack {
                    Spacer()
                    Text(error)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 24)
                        .padding(.bottom, 120)
                }
            }

            // Liquid Glass Tab Bar
            VStack {
                Spacer()
                LiquidGlassTabBar(
                    selectedTab: $selectedTab,
                    items: [
                        TabBarItem(icon: "house", title: "Home", tag: 0),
                        TabBarItem(icon: "questionmark.bubble", title: "Questions", tag: 1),
                        TabBarItem(icon: "clock.arrow.circlepath", title: "History", tag: 2),
                        TabBarItem(icon: "person", title: "Profile", tag: 3)
                    ]
                )
            }
        }
        .sheet(isPresented: $viewModel.showingAddPartner) {
            AddPartnerView()
        }
        .sheet(isPresented: $viewModel.showingInvitePartner) {
            InvitePartnerView()
        }
        .onAppear {
            Task {
                await viewModel.loadDashboardData()
            }
        }
    }
}

#Preview {
    DashboardView()
}
