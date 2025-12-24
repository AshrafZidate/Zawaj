//
//  SignUpUsernameView.swift
//  Zawaj
//
//  Created by Ashraf Zidate on 19/12/2025.
//

import SwiftUI

struct SignUpUsernameView: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator
    @State private var isCheckingAvailability: Bool = false
    @State private var isUsernameAvailable: Bool? = nil
    @State private var checkTask: Task<Void, Never>? = nil

    private var isValidFormat: Bool {
        let regex = "^[a-zA-Z0-9._-]+$"
        return !coordinator.username.isEmpty &&
               coordinator.username.range(of: regex, options: .regularExpression) != nil
    }

    private var canContinue: Bool {
        isValidFormat && isUsernameAvailable == true && !isCheckingAvailability
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
                    Text("Username")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.white)

                    Text("Choose your username")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))

                    // Username text field with @ prefix
                    HStack(spacing: 8) {
                        Text("@")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.leading, 16)

                        TextField("", text: $coordinator.username, prompt: Text("username").foregroundColor(.white.opacity(0.6)))
                            .font(.body)
                            .textFieldStyle(.plain)
                            .textContentType(.username)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .onChange(of: coordinator.username) { _, newValue in
                                // Cancel previous check
                                checkTask?.cancel()
                                isUsernameAvailable = nil

                                // Only check if format is valid
                                guard !newValue.isEmpty else { return }
                                let regex = "^[a-zA-Z0-9._-]+$"
                                guard newValue.range(of: regex, options: .regularExpression) != nil else { return }

                                // Debounce the availability check
                                checkTask = Task {
                                    isCheckingAvailability = true
                                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second debounce

                                    guard !Task.isCancelled else { return }

                                    let available = await coordinator.checkUsernameAvailability()

                                    guard !Task.isCancelled else { return }

                                    await MainActor.run {
                                        isUsernameAvailable = available
                                        isCheckingAvailability = false
                                    }
                                }
                            }

                        // Status indicator
                        if isCheckingAvailability {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                                .padding(.trailing, 16)
                        } else if let available = isUsernameAvailable {
                            Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(available ? .green : .red)
                                .padding(.trailing, 16)
                        }
                    }
                    .frame(height: 52)
                    .glassEffect(.clear)

                    // Username format info and validation feedback
                    if !coordinator.username.isEmpty && !isValidFormat {
                        Text("Username can only contain letters, numbers, and . - _")
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.8))
                    } else if isUsernameAvailable == false {
                        Text("This username is already taken")
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.8))
                    } else {
                        Text("Letters, numbers, periods, dashes, and underscores only")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()

                // Continue button - just above bottom
                GlassButtonPrimary(title: "Continue") {
                    coordinator.nextStep()
                }
                .disabled(!canContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}

#Preview {
    SignUpUsernameView()
        .environmentObject(OnboardingCoordinator())
}
