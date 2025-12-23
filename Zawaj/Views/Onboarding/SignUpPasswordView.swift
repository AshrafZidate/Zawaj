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
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

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
                GlassButton(title: "Continue") {
                    // Validate passwords match
                    guard coordinator.password == confirmPassword else {
                        errorMessage = "Passwords do not match"
                        showError = true
                        return
                    }

                    // Validate password length
                    guard coordinator.password.count >= 6 else {
                        errorMessage = "Password must be at least 6 characters"
                        showError = true
                        return
                    }

                    // Sign up with email and password
                    Task {
                        await coordinator.signUpWithEmail()
                        if coordinator.authenticationError != nil {
                            errorMessage = coordinator.authenticationError ?? "Unknown error"
                            showError = true
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .disabled(coordinator.isLoading)
            }

            // Loading overlay
            if coordinator.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {
                coordinator.authenticationError = nil
            }
        } message: {
            Text(errorMessage)
        }
    }
}

#Preview {
    SignUpPasswordView()
        .environmentObject(OnboardingCoordinator())
}
