//
//  EnableNotificationsView.swift
//  Zawaj
//
//  Created by Ashraf Zidate on 19/12/2025.
//

import SwiftUI
import UserNotifications

struct EnableNotificationsView: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator
    @State private var shouldShowView = true

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: 0) {
                // Back button and progress bar - just below dynamic island
                HStack {
                    Button(action: {
                        coordinator.previousStep()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    ProgressBar(progress: coordinator.currentStep.progress)
                }
                .frame(height: 44)
                .padding(.horizontal, 24)
                .padding(.top, 8)

                // Content section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Never miss a beat")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.white)

                    Text("Receive a notification when your partner completes their questions and when your daily questions are ready.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()

                // Action buttons
                VStack(spacing: 16) {
                    GlassButtonPrimary(title: "Enable push notifications") {
                        Task {
                            await requestNotificationPermission()
                        }
                    }

                    GlassButton(title: "Not now") {
                        Task {
                            await coordinator.completeOnboarding()
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .disabled(coordinator.isLoading)
            }

            // Loading overlay
            if coordinator.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
        .onAppear {
            Task {
                await checkNotificationStatus()
            }
        }
        .alert("Error", isPresented: .constant(coordinator.authenticationError != nil)) {
            Button("OK", role: .cancel) {
                coordinator.authenticationError = nil
            }
        } message: {
            if let error = coordinator.authenticationError {
                Text(error)
            }
        }
    }

    private func checkNotificationStatus() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        // If notifications are already authorized, skip this screen
        if settings.authorizationStatus == .authorized ||
           settings.authorizationStatus == .provisional ||
           settings.authorizationStatus == .ephemeral {
            await coordinator.completeOnboarding()
        }
    }

    private func requestNotificationPermission() async {
        let center = UNUserNotificationCenter.current()

        // Check current authorization status
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .notDetermined:
            // Permission not yet requested - show system dialog
            do {
                _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                // Complete onboarding after request
                await coordinator.completeOnboarding()
            } catch {
                await MainActor.run {
                    coordinator.authenticationError = error.localizedDescription
                }
            }
        case .authorized, .provisional, .ephemeral:
            // Already granted, proceed
            await coordinator.completeOnboarding()
        case .denied:
            // User previously denied - show alert to go to settings
            await MainActor.run {
                coordinator.authenticationError = "Notifications are disabled. Please enable them in Settings > Zawaj > Notifications to continue."
            }
        @unknown default:
            await coordinator.completeOnboarding()
        }
    }
}

#Preview {
    EnableNotificationsView()
        .environmentObject(OnboardingCoordinator())
}
