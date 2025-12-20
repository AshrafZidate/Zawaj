//
//  SignUpPasswordView.swift
//  Zawaj
//
//  Created by Ashraf Zidate on 19/12/2025.
//

import SwiftUI

struct SignUpPasswordView: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator
    @State private var confirmPassword: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var isConfirmPasswordVisible: Bool = false

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
                    Text("Password")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.white)

                    Text("Create a password")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))

                    // Password text field with show/hide toggle
                    HStack {
                        if isPasswordVisible {
                            TextField("", text: $coordinator.password, prompt: Text("Password").foregroundColor(.secondary))
                                .font(.body)
                                .textFieldStyle(.plain)
                                .textContentType(.newPassword)
                        } else {
                            SecureField("", text: $coordinator.password, prompt: Text("Password").foregroundColor(.secondary))
                                .font(.body)
                                .textFieldStyle(.plain)
                                .textContentType(.newPassword)
                        }

                        Button(action: {
                            isPasswordVisible.toggle()
                        }) {
                            Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

                    // Confirm password text field with show/hide toggle
                    HStack {
                        if isConfirmPasswordVisible {
                            TextField("", text: $confirmPassword, prompt: Text("Confirm Password").foregroundColor(.secondary))
                                .font(.body)
                                .textFieldStyle(.plain)
                                .textContentType(.newPassword)
                        } else {
                            SecureField("", text: $confirmPassword, prompt: Text("Confirm Password").foregroundColor(.secondary))
                                .font(.body)
                                .textFieldStyle(.plain)
                                .textContentType(.newPassword)
                        }

                        Button(action: {
                            isConfirmPasswordVisible.toggle()
                        }) {
                            Image(systemName: isConfirmPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()

                // Continue button - just above bottom
                GlassmorphicButton(title: "Continue") {
                    coordinator.nextStep()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}

#Preview {
    SignUpPasswordView()
        .environmentObject(OnboardingCoordinator())
}
