//
//  SignUpFullNameView.swift
//  Zawaj
//
//  Created by Ashraf Zidate on 19/12/2025.
//

import SwiftUI

struct SignUpFullNameView: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: 0) {
                // Progress bar - just below dynamic island
                ProgressBar(progress: coordinator.currentStep.progress)
                    .frame(height: 44)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                // Content section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Full Name")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.white)

                    Text("Enter your full name")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))

                    // Full name text field
                    HStack {
                        TextField("", text: $coordinator.fullName, prompt: Text("Full Name").foregroundColor(.white.opacity(0.6)))
                            .font(.body)
                            .foregroundColor(.white)
                            .textFieldStyle(.plain)
                            .textContentType(.name)
                            .autocapitalization(.words)

                        if !coordinator.fullName.isEmpty {
                            Button {
                                coordinator.fullName = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 52)
                    .glassEffect(.clear)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()

                // Continue button - just above bottom
                GlassButtonPrimary(title: "Continue") {
                    coordinator.nextStep()
                }
                .disabled(coordinator.fullName.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}

#Preview {
    SignUpFullNameView()
        .environmentObject(OnboardingCoordinator())
}
