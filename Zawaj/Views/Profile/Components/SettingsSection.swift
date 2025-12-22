//
//  SettingsSection.swift
//  Zawaj
//
//  Created on 2025-12-21.
//

import SwiftUI

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                content
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
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

        SettingsSection(title: "Account") {
            Text("Settings content here")
                .foregroundColor(.white)
                .padding()
        }
        .padding()
    }
}
