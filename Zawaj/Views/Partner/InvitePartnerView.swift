//
//  InvitePartnerView.swift
//  Zawaj
//
//  Created on 2025-12-22.
//

import SwiftUI

struct InvitePartnerView: View {
    @Environment(\.dismiss) var dismiss

    // Generate invite message and link
    private let inviteMessage = "Download the Zawāj app so we can get to know each other better for marriage! 💍"
    private let appStoreLink = "https://apps.apple.com/app/zawaj" // TODO: Replace with actual App Store link when published

    private var shareContent: String {
        return "\(inviteMessage)\n\n\(appStoreLink)"
    }

    var body: some View {
        NavigationView {
            ZStack {
                GradientBackground()

                VStack(spacing: 32) {
                    Spacer()

                    // Icon
                    Image(systemName: "envelope.badge.person.crop")
                        .font(.system(size: 80))
                        .foregroundColor(.white.opacity(0.8))

                    // Header
                    VStack(spacing: 12) {
                        Text("Invite your partner to Zawāj")
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text("Share Zawāj with someone special and start your journey together")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    // Share Button
                    ShareLink(item: shareContent) {
                        HStack(spacing: 12) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18, weight: .medium))

                            Text("Share Invite")
                                .font(.body.weight(.semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Color(red: 0.94, green: 0.26, blue: 0.42),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 48)

                    // Preview message
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preview:")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.white.opacity(0.7))

                        Text(shareContent)
                            .font(.body)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    Spacer()
                }
            }
            .navigationTitle("Invite Partner")
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
    InvitePartnerView()
}
