//
//  ProfileView.swift
//  Zawaj
//
//  Created on 2025-12-21.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()

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

            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        ProfileHeaderCard(user: viewModel.currentUser) {
                            viewModel.showingEditProfile = true
                        }

                        // Account Settings Section
                        SettingsSection(title: "Account") {
                            SettingsRow(icon: "envelope", title: "Email", value: viewModel.currentUser?.email)
                            SettingsRow(icon: "phone", title: "Phone", value: viewModel.currentUser?.phoneNumber)
                            SettingsButton(icon: "key", title: "Change Password") {
                                viewModel.showingChangePassword = true
                            }
                        }

                        // Profile Information Section
                        SettingsSection(title: "Profile Information") {
                            SettingsRow(icon: "person", title: "Gender", value: viewModel.currentUser?.gender)
                            SettingsRow(icon: "calendar", title: "Birthday", value: formattedBirthday())
                            SettingsRow(icon: "heart", title: "Relationship Status", value: viewModel.currentUser?.relationshipStatus)
                        }

                        // Relationship Preferences Section
                        SettingsSection(title: "Relationship Preferences") {
                            SettingsRow(icon: "clock", title: "Marriage Timeline", value: viewModel.currentUser?.marriageTimeline)
                            SettingsButton(icon: "list.star", title: "Topic Priorities") {
                                // TODO: Navigate to topic priorities editor
                            }
                            SettingsRow(icon: "text.bubble", title: "Answer Format", value: viewModel.currentUser?.answerPreference)
                        }

                        // Partner Connection Section
                        PartnerConnectionSection(
                            partner: viewModel.partner,
                            pendingRequests: viewModel.pendingPartnerRequests,
                            onDisconnect: { viewModel.showingDisconnectPartnerAlert = true }
                        )

                        // Notification Settings Section
                        NotificationSettingsSection(viewModel: viewModel)

                        // App Preferences Section
                        AppPreferencesSection(viewModel: viewModel)

                        // About & Support Section
                        SettingsSection(title: "About & Support") {
                            SettingsRow(icon: "info.circle", title: "App Version", value: "1.0.0")
                            SettingsButton(icon: "questionmark.circle", title: "Help & FAQ") {
                                // TODO: Navigate to help
                            }
                            SettingsButton(icon: "envelope", title: "Contact Support") {
                                // TODO: Open email
                            }
                            SettingsButton(icon: "doc.text", title: "Privacy Policy") {
                                // TODO: Open privacy policy
                            }
                            SettingsButton(icon: "doc.text", title: "Terms of Service") {
                                // TODO: Open terms
                            }

                            // Debug Tools (Development Only)
                            if AppConfig.isDevelopmentMode {
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.horizontal, 20)

                                SettingsButton(icon: "hammer.fill", title: "Developer Tools") {
                                    viewModel.showingDebugTools = true
                                }
                            }
                        }

                        // Sign Out Button
                        DestructiveButton(title: "Sign Out", icon: "rectangle.portrait.and.arrow.right") {
                            Task {
                                await viewModel.signOut()
                            }
                        }

                        // Delete Account Button
                        DestructiveButton(title: "Delete Account", icon: "trash", isPrimary: true) {
                            viewModel.showingDeleteAccountAlert = true
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
            }
        }
        .alert("Delete Account", isPresented: $viewModel.showingDeleteAccountAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteAccount(password: "")
                }
            }
        } message: {
            Text("This action cannot be undone. All your data, questions, and answers will be permanently deleted.")
        }
        .alert("Disconnect Partner", isPresented: $viewModel.showingDisconnectPartnerAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Disconnect", role: .destructive) {
                Task {
                    await viewModel.disconnectPartner()
                }
            }
        } message: {
            Text("Are you sure you want to disconnect from your partner? You can always reconnect later.")
        }
        .sheet(isPresented: $viewModel.showingDebugTools) {
            NavigationView {
                DebugQuestionBankView()
            }
        }
        .onAppear {
            Task {
                await viewModel.loadProfileData()
            }
        }
    }

    private func formattedBirthday() -> String {
        guard let birthday = viewModel.currentUser?.birthday else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: birthday)
    }
}

#Preview {
    ProfileView()
}
