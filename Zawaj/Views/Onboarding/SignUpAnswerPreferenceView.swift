//
//  SignUpAnswerPreferenceView.swift
//  Zawaj
//
//  Created on 2025-12-21.
//

import SwiftUI

struct SignUpAnswerPreferenceView: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator

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
                    Text("Answer Preference")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.white)

                    Text("How would you prefer to answer daily questions?")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()

                // Answer preference selection buttons
                VStack(spacing: 24) {
                    GlassButton(title: "Multiple Choice") {
                        coordinator.answerPreference = "Multiple Choice"
                        coordinator.nextStep()
                    }

                    GlassButton(title: "Open Ended") {
                        coordinator.answerPreference = "Open Ended"
                        coordinator.nextStep()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .swipeBack { coordinator.previousStep() }
    }
}

#Preview {
    SignUpAnswerPreferenceView()
        .environmentObject(OnboardingCoordinator())
}
