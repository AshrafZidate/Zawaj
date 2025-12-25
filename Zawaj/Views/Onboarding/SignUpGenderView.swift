//
//  SignUpGenderView.swift
//  Zawaj
//
//  Created by Ashraf Zidate on 19/12/2025.
//

import SwiftUI

struct SignUpGenderView: View {
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
                    Text("Gender")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.white)

                    Text("Select your gender")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()

                // Gender selection buttons
                VStack(spacing: 16) {
                    GlassButton(title: "Male", icon: "figure.stand") {
                        coordinator.gender = "Male"
                        coordinator.nextStep()
                    }

                    GlassButton(title: "Female", icon: "figure.stand.dress") {
                        coordinator.gender = "Female"
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
    SignUpGenderView()
        .environmentObject(OnboardingCoordinator())
}
