//
//  FindPartnerCard.swift
//  Zawaj
//
//  Created on 2025-12-21.
//

import SwiftUI

struct FindPartnerCard: View {
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.8))

            Text("Connect with your partner")
                .font(.title3.weight(.semibold))
                .foregroundColor(.white)

            Text("Answer questions together and strengthen your relationship")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            GlassmorphicButton(title: "Find Your Partner") {
                onTap()
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
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

        FindPartnerCard(onTap: {})
            .padding(.horizontal, 24)
    }
}
