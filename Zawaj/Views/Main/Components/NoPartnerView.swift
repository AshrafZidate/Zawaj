//
//  NoPartnerView.swift
//  Zawaj
//
//  Created on 2025-12-22.
//

import SwiftUI

struct NoPartnerView: View {
    let onAddPartner: () -> Void

    // Share content for invite
    private let inviteMessage = "Download the Zawāj app so we can get to know each other better for marriage! 💍"
    private let appStoreLink = "https://apps.apple.com/app/zawaj" // TODO: Replace with actual App Store link

    private var shareContent: String {
        return "\(inviteMessage)\n\n\(appStoreLink)"
    }

    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "person.2.slash")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.4))
                .padding(.top, 60)

            // Message
            VStack(spacing: 12) {
                Text("No Partner Yet")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white)

                Text("You don't have any partners. Once you have a partner, you'll see your set of daily questions here.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            // Buttons
            VStack(spacing: 16) {
                // Add Zawaj Partner Button
                Button(action: onAddPartner) {
                    HStack(spacing: 12) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 18, weight: .medium))

                        Text("Add a Zawāj partner")
                            .font(.body.weight(.medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(PlainButtonStyle())

                // Invite Partner Button with ShareLink
                ShareLink(
                    item: shareContent,
                    subject: Text("Join me on Zawāj"),
                    message: Text(inviteMessage)
                ) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .medium))

                        Text("Invite a partner to Zawāj")
                            .font(.body.weight(.medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)

            Spacer()
        }
    }
}

#Preview {
    ZStack {
        GradientBackground()
        NoPartnerView(onAddPartner: {})
    }
}
