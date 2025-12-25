//
//  NoPartnerView.swift
//  Zawaj
//
//  Created on 2025-12-22.
//

import SwiftUI

struct NoPartnerView: View {
    let pendingRequests: [PartnerRequest]
    let onAddPartner: () -> Void
    let onAcceptRequest: (PartnerRequest) -> Void
    let onDeclineRequest: (PartnerRequest) -> Void

    // Share content for invite
    private let inviteMessage = "Download the Zawaj app so we can get to know each other better for marriage!"
    private let appStoreLink = "https://apps.apple.com/app/zawaj" // TODO: Replace with actual App Store link

    private var shareContent: String {
        return "\(inviteMessage)\n\n\(appStoreLink)"
    }

    var body: some View {
        VStack(spacing: 24) {
            // Partner Requests Section
            if !pendingRequests.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Partner Requests")
                        .font(.headline)
                        .foregroundColor(.white)

                    ForEach(pendingRequests) { request in
                        NoPartnerRequestCard(
                            request: request,
                            onAccept: { onAcceptRequest(request) },
                            onDecline: { onDeclineRequest(request) }
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Icon
            Image(systemName: "person.2.slash")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.4))
                .padding(.top, pendingRequests.isEmpty ? 60 : 20)

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

// MARK: - Request Card for NoPartnerView

private struct NoPartnerRequestCard: View {
    let request: PartnerRequest
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(request.senderDisplayName)
                    .font(.body.weight(.medium))
                    .foregroundColor(.white)

                Text("@\(request.senderUsername)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    onAccept()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.glassProminent)
                .tint(.green)

                Button {
                    onDecline()
                } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.glassProminent)
                .tint(.red)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassEffect(.clear)
    }
}

#Preview {
    ZStack {
        GradientBackground()
        NoPartnerView(
            pendingRequests: [],
            onAddPartner: {},
            onAcceptRequest: { _ in },
            onDeclineRequest: { _ in }
        )
        .padding(.horizontal, 24)
    }
}
