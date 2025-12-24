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
    private let inviteMessage = "Download the Zawaj app so we can get to know each other better for marriage!"
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
                Text("No Partners Yet")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white)

                Text("You don't have any partners on Zawāj. Add or invite a partner to enjoy the full capabilities of Zawāj!")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            // Buttons
            VStack(spacing: 16) {
                GlassButton(title: "Send partner request", icon: "paperplane.fill") {
                    onAddPartner()
                }
                .frame(maxWidth: .infinity)

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
            }
            .padding(.top, 8)

            Spacer()
        }
    }
}

#Preview {
    ZStack {
        GradientBackground()
        NoPartnerView(onAddPartner: {})
            .padding(.horizontal, 24)
    }
}
