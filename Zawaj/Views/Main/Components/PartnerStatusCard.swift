//
//  PartnerStatusCard.swift
//  Zawaj
//
//  Created on 2025-12-21.
//

import SwiftUI

struct PartnerStatusCard: View {
    let partner: User?

    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.8))

            VStack(alignment: .leading, spacing: 4) {
                Text("Connected with \(partner?.fullName ?? "Partner")")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("Relationship: \(partner?.relationshipStatus ?? "")")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ZStack {
        GradientBackground()

        PartnerStatusCard(
            partner: User(
                id: "123",
                email: "alex@example.com",
                fullName: "Alex Johnson",
                relationshipStatus: "Married"
            )
        )
        .padding(.horizontal, 24)
    }
}
