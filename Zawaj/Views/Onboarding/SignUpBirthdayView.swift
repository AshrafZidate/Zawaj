//
//  SignUpBirthdayView.swift
//  Zawaj
//
//  Created by Ashraf Zidate on 19/12/2025.
//

import SwiftUI

struct SignUpBirthdayView: View {
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
                    Text("Birthday")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.white)

                    Text("Select your birthday")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))

                    // Date picker with iOS calendar style
                    DatePicker(
                        "",
                        selection: $coordinator.birthday,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .tint(.blue)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 13))
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()

                // Continue button - just above bottom
                GlassButton(title: "Continue") {
                    coordinator.nextStep()
                }
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
