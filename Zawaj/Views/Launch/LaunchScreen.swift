//
//  LaunchScreen.swift
//  Zawaj
//
//  Created by Ashraf Zidate on 19/12/2025.
//

import SwiftUI

struct LaunchScreen: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)

                Spacer()

                // Title
                VStack(spacing: 0) {
                    Text("Zawāj")
                        .font(.custom("Platypi", size: 64))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("الزَّواجُ")
                        .font(.custom("Amiri-Regular", size: 40))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)

                Spacer()

                // Tagline
                Text("Halal connection. Sacred intention.")
                    .font(.custom("NunitoSans-Regular", size: 20))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Spacer()

                // Login/Signup buttons
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
            }
        }
    }
}

#Preview {
    LaunchScreen()
        .environmentObject(OnboardingCoordinator())
}
