//
//  SignUpBirthdayView.swift
//  Zawaj
//
//  Created by Ashraf Zidate on 19/12/2025.
//

import SwiftUI

struct SignUpBirthdayView: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator

    private var isAtLeast16: Bool {
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: coordinator.birthday, to: now)
        return (ageComponents.year ?? 0) >= 16
    }

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
                    Text("Birthday")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.white)

                    Text("Select your birthday")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))

                    // Date picker with compact button style
                    DatePicker(
                        "Date of birth",
                        selection: $coordinator.birthday,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.compact)
                    .tint(.white)
                    .foregroundColor(.white)
                    .accentColor(.white)
                    .colorScheme(.dark)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .glassEffect(.clear)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()

                // Age requirement notice
                Text("Zawāj users must be at least 16 years old")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 12)

                // Continue button - just above bottom
                GlassButtonPrimary(title: "Continue") {
                    coordinator.nextStep()
                }
                .disabled(!isAtLeast16)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}

#Preview {
    SignUpBirthdayView()
        .environmentObject(OnboardingCoordinator())
}
