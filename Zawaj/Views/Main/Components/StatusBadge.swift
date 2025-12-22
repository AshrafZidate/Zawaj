//
//  StatusBadge.swift
//  Zawaj
//
//  Created on 2025-12-21.
//

import SwiftUI

struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.3), in: Capsule())
            .overlay(Capsule().stroke(color, lineWidth: 1))
    }
}

#Preview {
    ZStack {
        Color.black
        VStack(spacing: 12) {
            StatusBadge(text: "✓ You answered", color: .green)
            StatusBadge(text: "⏳ Waiting for partner", color: .orange)
        }
    }
}
