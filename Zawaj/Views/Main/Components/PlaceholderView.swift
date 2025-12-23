//
//  PlaceholderView.swift
//  Zawaj
//
//  Created on 2025-12-21.
//

import SwiftUI

struct PlaceholderView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.3))

            VStack(spacing: 8) {
                Text(title)
                    .font(.title.weight(.bold))
                    .foregroundColor(.white)

                Text(message)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 100)
    }
}

#Preview {
    ZStack {
        GradientBackground()
        PlaceholderView(icon: "questionmark.bubble", title: "Questions", message: "Daily questions will appear here")
    }
}
