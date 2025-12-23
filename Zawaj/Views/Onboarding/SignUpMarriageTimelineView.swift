//
//  SignUpMarriageTimelineView.swift
//  Zawaj
//
//  Created by Ashraf Zidate on 19/12/2025.
//

import SwiftUI

struct SignUpMarriageTimelineView: View {
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
                    Text("How soon are you hoping to become married?")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()

                // Timeline selection buttons
                VStack(spacing: 24) {
                    GlassButton(title: "1-3 Months") {
                        coordinator.marriageTimeline = "1-3 Months"
                        coordinator.nextStep()
                    }

                    GlassButton(title: "3-6 Months") {
                        coordinator.marriageTimeline = "3-6 Months"
                        coordinator.nextStep()
                    }

                    GlassButton(title: "6-12 Months") {
                        coordinator.marriageTimeline = "6-12 Months"
                        coordinator.nextStep()
                    }

                    GlassButton(title: "1-2 Years") {
                        coordinator.marriageTimeline = "1-2 Years"
                        coordinator.nextStep()
                    }

                    GlassButton(title: "Not sure") {
                        coordinator.marriageTimeline = "Not sure"
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
    SignUpMarriageTimelineView()
        .environmentObject(OnboardingCoordinator())
}
