//
//  LoginView.swift
//  Zawaj
//
//  Created by Ashraf Zidate on 19/12/2025.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showEmailNotFoundError: Bool = false
    @State private var showInvalidPasswordError: Bool = false
    @State private var showPasswordResetSent: Bool = false

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: 28) {
                // Logo
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .padding(.top, 20)

                // App branding
                VStack(spacing: 8) {
                    VStack(spacing: 0) {
                        Text("Zawāj")
                            .font(.custom("Platypi", size: 48))
                            .foregroundColor(.white)

                        Text("الزَّواجُ")
                            .font(.custom("Amiri", size: 32))
                            .foregroundColor(.white)
                    }

                    Text("Halal connection. Sacred intention.")
                        .font(.custom("NunitoSans", size: 20))
                        .foregroundColor(.white)
                }

                // Login options
                VStack(spacing: 16) {
                    // Continue with Google
                    Button(action: {
                        Task {
                            await coordinator.signInWithGoogle()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image("google-logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                            Text("Continue with Google")
                                .font(.body.weight(.semibold))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                    }
                    .buttonStyle(.glass)
                    .glassEffect(.clear)

                    // Continue with Apple (SignInWithAppleButton will replace this later)
                    Button(action: {
                        // Apple Sign-In requires SignInWithAppleButton from AuthenticationServices
                        // This is a placeholder - will be implemented with proper Apple Sign-In button
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "apple.logo")
                                .foregroundColor(.primary)
                            Text("Continue with Apple")
                                .font(.body.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                    }
                    .buttonStyle(.glass)
                    .glassEffect(.clear)

                    // OR divider
                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 1)
                        Text("OR")
                            .font(.body)
                            .foregroundColor(.white)
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 10)

                    // Email field
                    HStack {
                        TextField("", text: $email, prompt: Text("Email").foregroundColor(.white.opacity(0.6)))
                            .font(.body)
                            .foregroundColor(.white)
                            .textFieldStyle(.plain)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)

                        if !email.isEmpty {
                            Button {
                                email = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 52)
                    .glassEffect(.clear)

                    // Password field
                    HStack {
                        SecureField("", text: $password, prompt: Text("Password").foregroundColor(.white.opacity(0.6)))
                            .font(.body)
                            .foregroundColor(.white)
                            .textFieldStyle(.plain)

                        if !password.isEmpty {
                            Button {
                                password = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 52)
                    .glassEffect(.clear)
                    

                    // Login button
                    GlassButtonPrimary(title: "Login with Email") {
                        Task {
                            await coordinator.signInWithEmail(email: email, password: password)
                            if let error = coordinator.authenticationError {
                                if error.contains("does not exist") {
                                    showEmailNotFoundError = true
                                } else {
                                    showInvalidPasswordError = true
                                }
                            }
                        }
                    }
                    .disabled(email.isEmpty || password.isEmpty)

                    // Sign up link
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundColor(.white.opacity(0.8))
                        Button(action: {
                            coordinator.skipToStep(.signUpEmail)
                        }) {
                            Text("Sign up")
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                        }
                    }
                    .font(.body)
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .disabled(coordinator.isLoading)
            .opacity(coordinator.isLoading ? 0.6 : 1.0)

            // Loading overlay
            if coordinator.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
        .alert("Email Not Found", isPresented: $showEmailNotFoundError) {
            Button("OK", role: .cancel) {
                coordinator.authenticationError = nil
            }
        } message: {
            Text("The email you entered does not exist")
        }
        .alert("Invalid Password", isPresented: $showInvalidPasswordError) {
            Button("Try Again", role: .cancel) {
                password = ""
                coordinator.authenticationError = nil
            }
            Button("Reset Password", role: .destructive) {
                coordinator.authenticationError = nil
                Task {
                    await coordinator.sendPasswordReset(email: email)
                    showPasswordResetSent = true
                }
            }
        } message: {
            Text("The password you entered is incorrect")
        }
        .alert("Password Reset", isPresented: $showPasswordResetSent) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("An email to reset your Zawāj password has been sent to the email address")
        }
        .onAppear {
            if !coordinator.loginEmail.isEmpty {
                email = coordinator.loginEmail
                coordinator.loginEmail = ""
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(OnboardingCoordinator())
}
