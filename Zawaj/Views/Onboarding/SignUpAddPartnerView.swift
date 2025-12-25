//
//  SignUpAddPartnerView.swift
//  Zawaj
//
//  Created by Ashraf Zidate on 19/12/2025.
//

import SwiftUI

struct SignUpAddPartnerView: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator

    @State private var isValidating: Bool = false
    @State private var errorMessage: String?
    @State private var showingErrorAlert: Bool = false
    @State private var showingSuccessAlert: Bool = false

    // Share content for invite
    private let inviteMessage = "Download the Zawaj app so we can get to know each other better for marriage!"
    private let appStoreLink = "https://apps.apple.com/app/zawaj" // TODO: Replace with actual App Store link

    private var shareContent: String {
        return "\(inviteMessage)\n\n\(appStoreLink)"
    }

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
                            .foregroundColor(.white)
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

                    // Show queued partners
                    if !coordinator.pendingPartnerUsernames.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Partners to add:")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))

                            ForEach(coordinator.pendingPartnerUsernames, id: \.userId) { partner in
                                HStack {
                                    Image(systemName: "person.fill.checkmark")
                                        .foregroundColor(.green)
                                    Text("@\(partner.username)")
                                        .foregroundColor(.white)
                                    Spacer()
                                    Button {
                                        coordinator.pendingPartnerUsernames.removeAll { $0.userId == partner.userId }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                }
                                .font(.subheadline)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()

                // Action buttons
                VStack(spacing: 16) {
                    GlassButtonPrimary(title: "Add partner", icon: "plus") {
                        Task {
                            isValidating = true
                            if let error = await coordinator.validateAndQueuePartner(query: coordinator.partnerUsername) {
                                errorMessage = error
                                showingErrorAlert = true
                            } else {
                                showingSuccessAlert = true
                            }
                            isValidating = false
                        }
                    }
                    .disabled(coordinator.partnerUsername.trimmingCharacters(in: .whitespaces).isEmpty || isValidating)
                    .opacity(coordinator.partnerUsername.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)

                    ShareLink(item: shareContent) {
                        HStack(spacing: 12) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title2)
                            Text("Invite partner to Zawāj")
                                .font(.body.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                    }
                    .tint(nil)
                    .buttonStyle(.glass)
                    .glassEffect(.clear)

                    GlassButton(title: coordinator.pendingPartnerUsernames.isEmpty ? "I don't have a partner" : "Continue") {
                        coordinator.nextStep()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .alert("Unable to Add Partner", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .alert("Partner Added", isPresented: $showingSuccessAlert) {
            Button("Add Another") {
                coordinator.partnerUsername = ""
            }
            Button("Continue", role: .cancel) {
                coordinator.partnerUsername = ""
                coordinator.nextStep()
            }
        } message: {
            Text("Partner request will be sent once you complete your account setup.")
        }
        .swipeBack { coordinator.previousStep() }
    }
}

#Preview {
    SignUpAddPartnerView()
        .environmentObject(OnboardingCoordinator())
}
