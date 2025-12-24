//
//  InvitePartnerSheet.swift
//  Zawaj
//
//  Created on 2025-12-24.
//

import SwiftUI

struct InvitePartnerSheet: View {
    @Environment(\.dismiss) var dismiss

    // Share content for invite
    private let inviteMessage = "Download the Zawaj app so we can get to know each other better for marriage!"
    private let appStoreLink = "https://apps.apple.com/app/zawaj" // TODO: Replace with actual App Store link

    private var shareContent: String {
        return "\(inviteMessage)\n\n\(appStoreLink)"
    }

    var body: some View {
        NavigationView {
            ZStack {
                GradientBackground()

                VStack(spacing: 24) {
                    // Icon
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.top, 40)

                    // Title and description
                    VStack(spacing: 12) {
                        Text("Invite Partner")
                            .font(.title.weight(.bold))
                            .foregroundColor(.white)

                        Text("Share the app with your potential spouse so you can begin your journey together.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }

                    Spacer()

                    // Share button
                    ShareLink(
                        item: shareContent,
                        subject: Text("Join me on Zawaj"),
                        message: Text(inviteMessage)
                    ) {
                        HStack(spacing: 12) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title2)
                            Text("Share Invite Link")
                                .font(.body.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                    }
                    .buttonStyle(.glassProminent)
                    .glassEffect(.clear)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

#Preview {
    InvitePartnerSheet()
}
