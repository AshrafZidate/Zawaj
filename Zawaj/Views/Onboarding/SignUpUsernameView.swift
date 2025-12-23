//
//  SignUpUsernameView.swift
//  Zawaj
//
//  Created by Ashraf Zidate on 19/12/2025.
//

import SwiftUI

struct SignUpUsernameView: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator

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

                        TextField("", text: $coordinator.username, prompt: Text("username").foregroundColor(.secondary))
                            .font(.body)
                            .textFieldStyle(.plain)
                            .textContentType(.username)
                            .autocapitalization(.none)
                    }
                    .frame(height: 50)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()

                // Continue button - just above bottom
                GlassButton(title: "Continue") {
                    coordinator.nextStep()
                }
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
