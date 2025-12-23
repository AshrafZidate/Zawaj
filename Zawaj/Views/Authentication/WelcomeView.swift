//
//  WelcomeView.swift
//  Zawaj
//
//  Created by Ashraf Zidate on 19/12/2025.
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator

    var body: some View {
        ZStack {
            GradientBackground()

            // Center content - logo and text
            VStack(spacing: 40) {
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)

                // Welcome text
                VStack(spacing: 12) {
                    Text("Welcome to Zawāj")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)

                    Text("Zawāj is a tool designed for Muslim couples preparing for marriage.\nLearn about each other through coordinated daily questions.")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.bottom, 150) // Offset to account for buttons at bottom

            // Bottom section with buttons - pinned to bottom
            VStack(spacing: 16) {
                GlassButton(title: "Log In") {
                    coordinator.skipToStep(.login)
                }

                GlassButton(title: "Sign Up") {
                    coordinator.skipToStep(.signUpEmail)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(OnboardingCoordinator())
}
