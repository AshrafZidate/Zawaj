//
//  EmailVerificationView.swift
//  Zawaj
//
//  Created on 2025-12-21.
//

import SwiftUI

struct EmailVerificationView: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator
    @State private var showResendSuccess = false
    @State private var resendCooldown = 0
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: 0) {
                // Header: Back button and progress bar
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
                VStack(alignment: .leading, spacing: 20) {
                    Text("Verify your email")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.white)

                    Text("We've sent a verification link to:")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))

                    // Email display
                    Text(coordinator.email)
                        .font(.body.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .glassEffect(.clear)

                    Text("Click the link in the email to verify your account, then tap Continue below.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))

                    // Resend button section
                    VStack(spacing: 12) {
                        if showResendSuccess {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Email sent!")
                                    .font(.callout)
                                    .foregroundColor(.white)
                            }
                        }

                        GlassButton(title: resendCooldown > 0 ? "Resend in \(resendCooldown)s" : "Resend verification email", icon: "arrow.clockwise") {
                            resendVerificationEmail()
                        }
                        .disabled(resendCooldown > 0 || coordinator.isLoading)
                    }
                    .padding(.top, 8)

                    // Help text
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Didn't receive the email?")
                            .font(.callout)
                            .foregroundColor(.white.opacity(0.7))

                        Text("• Check your spam folder")
                            .font(.callout)
                            .foregroundColor(.white.opacity(0.6))
                        Text("• Make sure \(coordinator.email) is correct")
                            .font(.callout)
                            .foregroundColor(.white.opacity(0.6))
                        Text("• Try resending the email")
                            .font(.callout)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()

                // Continue button
                GlassButtonPrimary(title: "Continue") {
                    Task {
                        coordinator.isLoading = true

                        // Check if email is verified
                        let isVerified = await coordinator.checkEmailVerification()

                        if isVerified {
                            // Email verified - proceed to next step
                            await MainActor.run {
                                coordinator.isLoading = false
                                coordinator.nextStep()
                            }
                        } else {
                            // Not verified - show error
                            await MainActor.run {
                                coordinator.authenticationError = "Please verify your email before continuing. Check your inbox and click the verification link."
                                coordinator.isLoading = false
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
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
        .alert("Error", isPresented: .constant(coordinator.authenticationError != nil)) {
            Button("OK", role: .cancel) {
                coordinator.authenticationError = nil
            }
        } message: {
            if let error = coordinator.authenticationError {
                Text(error)
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func resendVerificationEmail() {
        Task {
            coordinator.isLoading = true
            coordinator.authenticationError = nil

            do {
                try await coordinator.resendEmailVerification()

                await MainActor.run {
                    coordinator.isLoading = false
                    showResendSuccess = true
                    startCooldown()

                    // Hide success message after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showResendSuccess = false
                    }
                }
            } catch {
                await MainActor.run {
                    coordinator.authenticationError = error.localizedDescription
                    coordinator.isLoading = false
                }
            }
        }
    }

    private func startCooldown() {
        resendCooldown = 60 // 60 second cooldown
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if resendCooldown > 0 {
                resendCooldown -= 1
            } else {
                timer?.invalidate()
            }
        }
    }
}

#Preview {
    EmailVerificationView()
        .environmentObject(OnboardingCoordinator())
}
