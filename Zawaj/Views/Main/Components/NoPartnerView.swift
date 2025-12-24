//
//  NoPartnerView.swift
//  Zawaj
//
//  Created on 2025-12-22.
//

import SwiftUI

struct NoPartnerView: View {
    let onAddPartner: () -> Void
    let onInvitePartner: () -> Void

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

                GlassButton(title: "Invite partner to Zawāj", icon: "square.and.arrow.up") {
                    onInvitePartner()
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 8)

            Spacer()
        }
    }
}

#Preview {
    ZStack {
        GradientBackground()
        NoPartnerView(onAddPartner: {}, onInvitePartner: {})
            .padding(.horizontal, 24)
    }
}
