//
//  EnableNotificationsView.swift
//  Zawaj
//
//  Created by Ashraf Zidate on 19/12/2025.
//

import SwiftUI

struct EnableNotificationsView: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator

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
                VStack(spacing: 24) {
                    GlassmorphicButton(title: "Enable push notifications") {
                        // Request notification permission
                        coordinator.nextStep()
                    }

                    GlassmorphicButton(title: "Not now") {
                        // Skip notifications
                        coordinator.nextStep()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}

#Preview {
    EnableNotificationsView()
        .environmentObject(OnboardingCoordinator())
}
