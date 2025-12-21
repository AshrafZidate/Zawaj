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
                // Progress indicator
                ProgressView(value: OnboardingStep.signUpEmail.progress)
                    .tint(.white)
                    .background(Color.white.opacity(0.3))
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                // Back button
                HStack {
                    Button(action: {
                        coordinator.previousStep()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .frame(height: 44)
                .padding(.horizontal, 24)
                .padding(.top, 16)

                ScrollView {
                    VStack(spacing: 32) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 120, height: 120)

                            Image(systemName: "envelope.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 40)

                        // Title and description
                        VStack(spacing: 16) {
                            Text("Verify your email")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)

                            VStack(spacing: 12) {
                                Text("We've sent a verification link to:")
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.center)

                                Text(coordinator.email)
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.15))
                                    )

                                Text("Click the link in the email to verify your account, then continue below.")
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal, 24)

                        // Resend button
                        VStack(spacing: 12) {
                            if showResendSuccess {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Email sent!")
                                        .font(.body)
                                        .foregroundColor(.white)
                                }
                                .padding(.vertical, 8)
                            }

                            Button(action: {
                                resendVerificationEmail()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.body)
                                    Text(resendCooldown > 0 ? "Resend in \(resendCooldown)s" : "Resend verification email")
                                        .font(.body.weight(.medium))
                                }
                                .foregroundColor(resendCooldown > 0 ? .white.opacity(0.5) : .white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(resendCooldown > 0 ? Color.white.opacity(0.3) : Color.white, lineWidth: 2)
                                )
                            }
                            .disabled(resendCooldown > 0 || coordinator.isLoading)
                        }
                        .padding(.horizontal, 24)

                        // Help text
                        VStack(spacing: 8) {
                            Text("Didn't receive the email?")
                                .font(.callout)
                                .foregroundColor(.white.opacity(0.7))

                            Text("• Check your spam folder\n• Make sure \(coordinator.email) is correct\n• Try resending the email")
                                .font(.callout)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 32)

                        Spacer(minLength: 40)

                        // Continue button
                        GlassmorphicButton(title: "Continue") {
                            coordinator.nextStep()
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    }
                }
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
