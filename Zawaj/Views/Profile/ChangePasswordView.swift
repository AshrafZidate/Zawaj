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

    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.18, green: 0.05, blue: 0.35),
                        Color(red: 0.72, green: 0.28, blue: 0.44)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Current Password
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Password")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))

                        SecureField("", text: $currentPassword)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(.white)
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }

                    // New Password
                    VStack(alignment: .leading, spacing: 8) {
                        Text("New Password")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))

                        SecureField("", text: $newPassword)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(.white)
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }

                    // Confirm New Password
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm New Password")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))

                        SecureField("", text: $confirmPassword)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(.white)
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }

                    // Error Message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }

                    // Change Password Button
                    Button(action: {
                        Task {
                            await changePassword()
                        }
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Change Password")
                                    .font(.body.weight(.medium))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.94, green: 0.26, blue: 0.42),
                                    Color(red: 0.82, green: 0.16, blue: 0.32)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                    }
                    .disabled(isLoading || currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty)
                    .opacity((isLoading || currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) ? 0.6 : 1.0)

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
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
        }
    }

    private func changePassword() async {
        errorMessage = nil

        // Validate passwords match
        guard newPassword == confirmPassword else {
            errorMessage = "New passwords do not match"
            return
        }

        // Validate password length
        guard newPassword.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }

        isLoading = true
        await viewModel.changePassword(currentPassword: currentPassword, newPassword: newPassword)
        isLoading = false

        if let error = viewModel.error {
            errorMessage = error
        } else {
            // Success - dismiss the sheet
            dismiss()
        }
    }
}

#Preview {
    ChangePasswordView(viewModel: ProfileViewModel())
}
