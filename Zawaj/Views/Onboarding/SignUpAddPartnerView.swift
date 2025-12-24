//
//  SignUpAddPartnerView.swift
//  Zawaj
//
//  Created by Ashraf Zidate on 19/12/2025.
//

import SwiftUI

struct SignUpAddPartnerView: View {
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
                    Text("Add your partner")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.white)

                    Text("Add your partner so you can begin your Zawāj journey together.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))

                    // Partner username text field
                    HStack {
                        TextField("", text: $coordinator.partnerUsername, prompt: Text("Partner's username or email").foregroundColor(.white.opacity(0.6)))
                            .font(.body)
                            .textFieldStyle(.plain)
                            .textContentType(.username)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()

                        if !coordinator.partnerUsername.isEmpty {
                            Button {
                                coordinator.partnerUsername = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 52)
                    .glassEffect(.clear)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()

                // Action buttons
                VStack(spacing: 16) {
                    GlassButtonPrimary(title: "Send partner request") {
                        // Send partner request
                        coordinator.nextStep()
                    }
                    .disabled(coordinator.partnerUsername.trimmingCharacters(in: .whitespaces).isEmpty)

                    GlassButton(title: "Invite partner to Zawāj") {
                        // Invite partner via share sheet
                        coordinator.nextStep()
                    }

                    GlassButton(title: "I don't have a partner") {
                        // Skip partner connection
                        coordinator.nextStep()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}

#Preview {
    SignUpAddPartnerView()
        .environmentObject(OnboardingCoordinator())
}
