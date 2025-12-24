//
//  GlassButton.swift
//  Zawaj
//
//  Created on 2025-12-20.
//

import SwiftUI

// MARK: - Glass Button (Normal - No specific meaning)

struct GlassButton: View {
    let title: String
    var icon: String? = nil
    var tint: Color? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title2)
                }
                Text(title)
                    .font(.body.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
        }
        .tint(tint?.opacity(0.7))
        .buttonStyle(.glass)
        .glassEffect(.clear)

    }
}

// MARK: - Glass Button Primary (Default action - accent color filled)

struct GlassButtonPrimary: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title2)
                }
                Text(title)
                    .font(.body.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
        }
        .buttonStyle(.glassProminent)
        .glassEffect(.clear)
    }
}

// MARK: - Glass Button Destructive (Data destruction - red color)

struct GlassButtonDestructive: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(role: .destructive, action: action) {
            Text(title)
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
        }
        .buttonStyle(.glassProminent)
        .glassEffect(.clear)
    }
}

// MARK: - Previews

#Preview("Glass Button Roles") {
    ZStack {
        GradientBackground()

        VStack(spacing: 16) {
            GlassButton(title: "Normal") {}
            GlassButtonPrimary(title: "Primary") {}
            GlassButtonDestructive(title: "Destructive") {}
        }
        .padding(.horizontal, 24)
    }
}
