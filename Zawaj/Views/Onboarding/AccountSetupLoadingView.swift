//
//  AccountSetupLoadingView.swift
//  Zawaj
//
//  Created on 2025-12-20.
//

import SwiftUI

struct AccountSetupLoadingView: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator
    @State private var progress: Double = 0.0
    @State private var showContinueButton: Bool = false

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
                    .padding(.bottom, 60)

                Spacer()

                // Instructional text
                VStack(spacing: 16) {
                    Text("We're finalizing your account setup")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("This shouldn't take any longer than 30 seconds")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)

                // Loading bar
                VStack(spacing: 12) {
                    // Progress bar container
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 8)

                            // Progress fill
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white)
                                .frame(width: geometry.size.width * progress, height: 8)
                                .animation(.linear(duration: 0.1), value: progress)
                        }
                    }
                    .frame(height: 8)
                    .padding(.horizontal, 40)

                    // Percentage text
                    Text("\(Int(progress * 100))%")
                        .font(.body.weight(.medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.bottom, 60)

                // Continue button (appears after loading completes)
                if showContinueButton {
                    GlassButton(title: "Continue to Zawāj") {
                        // TODO: Navigate to main app
                        coordinator.skipToStep(.completed)
                    }
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .scale))
                } else {
                    // Placeholder to maintain layout
                    Color.clear
                        .frame(height: 50)
                        .padding(.horizontal, 24)
                }

                Spacer()
            }
            .padding(.vertical, 60)
        }
        .onAppear {
            startLoading()
        }
    }

    private func startLoading() {
        // Animate progress from 0 to 1 over 30 seconds
        let totalDuration: Double = 30.0
        let updateInterval: Double = 0.1 // Update every 0.1 seconds
        let incrementPerUpdate = updateInterval / totalDuration

        Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { timer in
            if progress < 1.0 {
                progress += incrementPerUpdate

                // Ensure we don't exceed 100%
                if progress >= 1.0 {
                    progress = 1.0
                    timer.invalidate()

                    // Show continue button after a brief delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            showContinueButton = true
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    AccountSetupLoadingView()
        .environmentObject(OnboardingCoordinator())
}
