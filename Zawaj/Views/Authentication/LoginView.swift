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
                .padding(.top, 8)

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
                        // Google sign in
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
                        .frame(height: 50)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 25))
                    }
                    .buttonStyle(.plain)

                    // Continue with Apple
                    Button(action: {
                        // Apple sign in
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "apple.logo")
                                .foregroundColor(.primary)
                            Text("Continue with Apple")
                                .font(.body.weight(.semibold))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 25))
                    }
                    .buttonStyle(.plain)

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
                    TextField("", text: $email, prompt: Text("Email").foregroundColor(.secondary))
                        .font(.body)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 20)
                        .frame(height: 52)
                        .background(Color(red: 0.88, green: 0.89, blue: 0.91), in: RoundedRectangle(cornerRadius: 26))
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)

                    // Password field
                    SecureField("", text: $password, prompt: Text("Password").foregroundColor(.secondary))
                        .font(.body)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 20)
                        .frame(height: 52)
                        .background(Color(red: 0.88, green: 0.89, blue: 0.91), in: RoundedRectangle(cornerRadius: 26))

                    // Login button
                    Button(action: {
                        // Login action
                    }) {
                        Text("Login with Email")
                            .font(.body.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue, in: RoundedRectangle(cornerRadius: 25))
                    }

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
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(OnboardingCoordinator())
}
