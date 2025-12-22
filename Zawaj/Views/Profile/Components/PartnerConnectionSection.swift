//
//  PartnerConnectionSection.swift
//  Zawaj
//
//  Created on 2025-12-21.
//

import SwiftUI

struct PartnerConnectionSection: View {
    let partner: User?
    let pendingRequests: [PartnerRequest]
    let onDisconnect: () -> Void

    var body: some View {
        SettingsSection(title: "Partner Connection") {
            if let partner = partner {
                // Connected Partner
                HStack(spacing: 16) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(partner.fullName)
                            .font(.body.weight(.medium))
                            .foregroundColor(.white)
                        Text("@\(partner.username)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()

                    Button("Disconnect") {
                        onDisconnect()
                    }
                    .font(.body)
                    .foregroundColor(.red)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            } else {
                SettingsButton(icon: "person.badge.plus", title: "Find Partner") {
                    // TODO: Navigate to partner search
                }
            }

            if !pendingRequests.isEmpty {
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.horizontal, 20)

                SettingsButton(icon: "bell.badge", title: "Pending Requests (\(pendingRequests.count))") {
                    // TODO: Navigate to partner requests
                }
            }
        }
    }
}
