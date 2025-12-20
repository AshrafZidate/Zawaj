//
//  GlassmorphicButton.swift
//  Zawaj
//
//  Created on 2025-12-20.
//

import SwiftUI

struct GlassmorphicButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 25))
        }
        .buttonStyle(.plain)
    }
}
