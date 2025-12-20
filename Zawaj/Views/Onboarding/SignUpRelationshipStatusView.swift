//
//  SignUpRelationshipStatusView.swift
//  Zawaj
//
//  Created by Ashraf Zidate on 19/12/2025.
//

import SwiftUI

struct SignUpRelationshipStatusView: View {
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
                    Text("What is your current relationship status?")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()

                // Relationship status selection buttons
                VStack(spacing: 24) {
                    GlassmorphicButton(title: "Single") {
                        coordinator.relationshipStatus = "Single"
                        coordinator.nextStep()
                    }

                    GlassmorphicButton(title: "Talking Stage") {
                        coordinator.relationshipStatus = "Talking Stage"
                        coordinator.nextStep()
                    }

                    GlassmorphicButton(title: "Engaged") {
                        coordinator.relationshipStatus = "Engaged"
                        coordinator.nextStep()
                    }

                    GlassmorphicButton(title: "Married") {
                        coordinator.relationshipStatus = "Married"
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
    SignUpRelationshipStatusView()
        .environmentObject(OnboardingCoordinator())
}
