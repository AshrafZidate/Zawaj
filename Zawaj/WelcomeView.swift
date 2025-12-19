//
//  WelcomeView.swift
//  Zawaj
//
//  Created by Ashraf Zidate on 19/12/2025.
//

import SwiftUI

struct WelcomeView: View {
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
                // Top section with logo
                Spacer()

                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)

                Spacer()

                // Middle section with welcome text
                VStack(alignment: .leading, spacing: 12) {
                    Text("Welcome")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)

                    Text("Zawāj is a tool designed for Muslim couples preparing for marriage.\nLearn about each other through coordinated daily questions.")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                // Bottom section with buttons
                VStack(spacing: 16) {
                    GlassmorphicButton(title: "Log In") {
                        // Login action
                    }

                    GlassmorphicButton(title: "Sign Up") {
                        // Sign up action
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.vertical, 100)
        }
    }
}

struct GlassmorphicButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 25))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    WelcomeView()
}
