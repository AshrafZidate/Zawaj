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
            Image(systemName: "person.2.circle")
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

                // Invite Partner Button
                Button(action: onInvitePartner) {
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.badge.person.crop")
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
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.18, green: 0.05, blue: 0.35),
                Color(red: 0.72, green: 0.28, blue: 0.44)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )

        NoPartnerView(
            onAddPartner: {},
            onInvitePartner: {}
        )
    }
}
