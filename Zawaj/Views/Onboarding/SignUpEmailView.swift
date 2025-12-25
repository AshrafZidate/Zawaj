//
//  SignUpEmailView.swift
//  Zawaj
//
//  Created by Ashraf Zidate on 19/12/2025.
//

import SwiftUI

struct SignUpEmailView: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
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
                    Text("Email")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.white)

                    Text("Enter your email address")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))

                    // Email text field
                    HStack {
                        TextField("", text: $coordinator.email, prompt: Text("Email").foregroundColor(.white.opacity(0.6)))
                            .font(.body)
                            .foregroundColor(.white)
                            .textFieldStyle(.plain)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)

                        if !coordinator.email.isEmpty {
                            Button {
                                coordinator.email = ""
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
                .disabled(!isValidEmail(coordinator.email))
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .swipeBack { coordinator.previousStep() }
    }
}

#Preview {
    SignUpEmailView()
        .environmentObject(OnboardingCoordinator())
}
