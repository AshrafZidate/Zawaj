//
//  ProfileHeaderCard.swift
//  Zawaj
//
//  Created on 2025-12-21.
//

import SwiftUI

struct ProfileHeaderCard: View {
    let user: User?
    let onEdit: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Initials Badge (no photo)
            ProfileInitialsBadge(initials: String(user?.fullName.prefix(2).uppercased() ?? "U"))
                .frame(width: 100, height: 100)

            // Name and Username
            VStack(spacing: 4) {
                Text(user?.fullName ?? "Loading...")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)

                Text("@\(user?.username ?? "")")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }

            // Edit Profile Button
            GlassmorphicButton(title: "Edit Profile", action: onEdit)
                .frame(maxWidth: 200)
        }
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

struct ProfileInitialsBadge: View {
    let initials: String

    var body: some View {
        Circle()
            .fill(Color.white.opacity(0.2))
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
            )
            .overlay(
                Text(initials)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            )
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

        ProfileHeaderCard(
            user: User(
                id: "123",
                email: "test@example.com",
                fullName: "Ashraf Zidate",
                username: "ashraf"
            ),
            onEdit: {}
        )
        .padding()
    }
}
