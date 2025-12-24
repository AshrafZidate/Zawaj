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
    @State private var showEmailAlreadyInUseError: Bool = false
    @State private var errorMessage: String = ""

    private var hasMinLength: Bool {
        coordinator.password.count >= 8
    }

    private var hasUppercase: Bool {
        coordinator.password.contains(where: { $0.isUppercase })
    }

    private var hasNumber: Bool {
        coordinator.password.contains(where: { $0.isNumber })
    }

    private var passwordsMatch: Bool {
        !confirmPassword.isEmpty && coordinator.password == confirmPassword
    }

    private var isPasswordValid: Bool {
        hasMinLength && hasUppercase && hasNumber && passwordsMatch
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
                    Text("Password")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.white)

                    Text("Create a password")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))

                    // Password text field with show/hide toggle
                    HStack {
                        if isPasswordVisible {
                            TextField("", text: $coordinator.password, prompt: Text("Password").foregroundColor(.white.opacity(0.6)))
                                .font(.body)
                                .textFieldStyle(.plain)
                                .textContentType(.newPassword)
                        } else {
                            SecureField("", text: $coordinator.password, prompt: Text("Password").foregroundColor(.white.opacity(0.6)))
                                .font(.body)
                                .textFieldStyle(.plain)
                                .textContentType(.newPassword)
                        }

                        if !coordinator.password.isEmpty {
                            Button {
                                coordinator.password = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Button(action: {
                            isPasswordVisible.toggle()
                        }) {
                            Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 52)
                    .glassEffect(.clear)

                    // Confirm password text field with show/hide toggle
                    HStack {
                        if isConfirmPasswordVisible {
                            TextField("", text: $confirmPassword, prompt: Text("Confirm Password").foregroundColor(.white.opacity(0.6)))
                                .font(.body)
                                .textFieldStyle(.plain)
                                .textContentType(.newPassword)
                        } else {
                            SecureField("", text: $confirmPassword, prompt: Text("Confirm Password").foregroundColor(.white.opacity(0.6)))
                                .font(.body)
                                .textFieldStyle(.plain)
                                .textContentType(.newPassword)
                        }

                        if !confirmPassword.isEmpty {
                            Button {
                                confirmPassword = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Button(action: {
                            isConfirmPasswordVisible.toggle()
                        }) {
                            Image(systemName: isConfirmPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 52)
                    .glassEffect(.clear)

                    // Password requirements
                    VStack(alignment: .leading, spacing: 6) {
                        PasswordRequirementRow(text: "Minimum of 8 characters", isMet: hasMinLength)
                        PasswordRequirementRow(text: "Minimum of 1 upper case letter", isMet: hasUppercase)
                        PasswordRequirementRow(text: "Minimum of 1 number", isMet: hasNumber)
                        PasswordRequirementRow(text: "Passwords match", isMet: passwordsMatch)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()

                // Continue button - just above bottom
                GlassButtonPrimary(title: "Continue") {
                    // Sign up with email and password
                    Task {
                        await coordinator.signUpWithEmail()
                        if let error = coordinator.authenticationError {
                            if error.contains("already in use") {
                                showEmailAlreadyInUseError = true
                            } else {
                                errorMessage = error
                                showError = true
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .disabled(!isPasswordValid || coordinator.isLoading)
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
        .alert("Sign Up Failed", isPresented: $showError) {
            Button("OK", role: .cancel) {
                coordinator.authenticationError = nil
            }
        } message: {
            Text(errorMessage)
        }
        .alert("Email Already in Use", isPresented: $showEmailAlreadyInUseError) {
            Button("Sign up with a different email", role: .cancel) {
                coordinator.authenticationError = nil
                coordinator.email = ""
                coordinator.skipToStep(.signUpEmail)
            }
            Button("Log in with this email") {
                coordinator.authenticationError = nil
                coordinator.loginEmail = coordinator.email
                coordinator.skipToStep(.login)
            }
        } message: {
            Text("The email \(coordinator.email) is already associated with an account")
        }
        .onDisappear {
            coordinator.password = ""
            confirmPassword = ""
        }
    }
}

// MARK: - Password Requirement Row

private struct PasswordRequirementRow: View {
    let text: String
    let isMet: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .font(.subheadline)
                .foregroundColor(isMet ? .green : .white.opacity(0.5))
            Text(text)
                .font(.subheadline)
                .foregroundColor(isMet ? .white : .white.opacity(0.5))
        }
    }
}

#Preview {
    SignUpPasswordView()
        .environmentObject(OnboardingCoordinator())
}
