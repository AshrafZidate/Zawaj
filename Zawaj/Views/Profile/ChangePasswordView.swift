//
//  ChangePasswordView.swift
//  Zawaj
//
//  Created on 2025-12-22.
//

import SwiftUI

struct ChangePasswordView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ProfileViewModel

    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var errorMessage: String?
    @State private var isLoading: Bool = false
    @State private var showError: Bool = false
    @State private var showSuccess: Bool = false

    // Password visibility toggles
    @State private var isCurrentPasswordVisible: Bool = false
    @State private var isNewPasswordVisible: Bool = false
    @State private var isConfirmPasswordVisible: Bool = false

    // Password validation
    private var hasMinLength: Bool {
        newPassword.count >= 8
    }

    private var hasUppercase: Bool {
        newPassword.contains(where: { $0.isUppercase })
    }

    private var hasNumber: Bool {
        newPassword.contains(where: { $0.isNumber })
    }

    private var passwordsMatch: Bool {
        !confirmPassword.isEmpty && newPassword == confirmPassword
    }

    private var isPasswordValid: Bool {
        hasMinLength && hasUppercase && hasNumber && passwordsMatch
    }

    private var canSubmit: Bool {
        !currentPassword.isEmpty && isPasswordValid && !isLoading
    }

    var body: some View {
        NavigationView {
            ZStack {
                GradientBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Current Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Password")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))

                            HStack {
                                if isCurrentPasswordVisible {
                                    TextField("", text: $currentPassword, prompt: Text("Enter current password").foregroundColor(.white.opacity(0.6)))
                                        .font(.body)
                                        .textFieldStyle(.plain)
                                        .textContentType(.password)
                                } else {
                                    SecureField("", text: $currentPassword, prompt: Text("Enter current password").foregroundColor(.white.opacity(0.6)))
                                        .font(.body)
                                        .textFieldStyle(.plain)
                                        .textContentType(.password)
                                }

                                if !currentPassword.isEmpty {
                                    Button {
                                        currentPassword = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Button(action: {
                                    isCurrentPasswordVisible.toggle()
                                }) {
                                    Image(systemName: isCurrentPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                        .font(.body)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                            .glassEffect(.clear)
                        }

                        // New Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("New Password")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))

                            HStack {
                                if isNewPasswordVisible {
                                    TextField("", text: $newPassword, prompt: Text("Enter new password").foregroundColor(.white.opacity(0.6)))
                                        .font(.body)
                                        .textFieldStyle(.plain)
                                        .textContentType(.newPassword)
                                } else {
                                    SecureField("", text: $newPassword, prompt: Text("Enter new password").foregroundColor(.white.opacity(0.6)))
                                        .font(.body)
                                        .textFieldStyle(.plain)
                                        .textContentType(.newPassword)
                                }

                                if !newPassword.isEmpty {
                                    Button {
                                        newPassword = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Button(action: {
                                    isNewPasswordVisible.toggle()
                                }) {
                                    Image(systemName: isNewPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                        .font(.body)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                            .glassEffect(.clear)
                        }

                        // Confirm New Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm New Password")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))

                            HStack {
                                if isConfirmPasswordVisible {
                                    TextField("", text: $confirmPassword, prompt: Text("Confirm new password").foregroundColor(.white.opacity(0.6)))
                                        .font(.body)
                                        .textFieldStyle(.plain)
                                        .textContentType(.newPassword)
                                } else {
                                    SecureField("", text: $confirmPassword, prompt: Text("Confirm new password").foregroundColor(.white.opacity(0.6)))
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
                        }

                        // Password requirements checklist
                        VStack(alignment: .leading, spacing: 6) {
                            ChangePasswordRequirementRow(text: "Minimum of 8 characters", isMet: hasMinLength)
                            ChangePasswordRequirementRow(text: "Minimum of 1 upper case letter", isMet: hasUppercase)
                            ChangePasswordRequirementRow(text: "Minimum of 1 number", isMet: hasNumber)
                            ChangePasswordRequirementRow(text: "Passwords match", isMet: passwordsMatch)
                        }
                        .padding(.top, 8)

                        Spacer(minLength: 24)

                        // Change Password Button
                        GlassButtonPrimary(title: "Change Password") {
                            Task {
                                await changePassword()
                            }
                        }
                        .disabled(!canSubmit)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 24)
                }

                // Loading overlay
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()

                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.18, green: 0.05, blue: 0.35),
                        Color(red: 0.72, green: 0.28, blue: 0.44)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                ),
                for: .navigationBar
            )
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Password Change Failed", isPresented: $showError) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "An error occurred. Please try again.")
            }
            .alert("Password Changed", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your password has been updated successfully.")
            }
        }
    }

    private func changePassword() async {
        errorMessage = nil
        isLoading = true

        await viewModel.changePassword(currentPassword: currentPassword, newPassword: newPassword)

        isLoading = false

        if let error = viewModel.error {
            errorMessage = error
            showError = true
        } else {
            showSuccess = true
        }
    }
}

// MARK: - Password Requirement Row

private struct ChangePasswordRequirementRow: View {
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
    ChangePasswordView(viewModel: ProfileViewModel())
}
