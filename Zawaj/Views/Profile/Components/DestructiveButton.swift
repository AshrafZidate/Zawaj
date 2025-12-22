//
//  DestructiveButton.swift
//  Zawaj
//
//  Created on 2025-12-21.
//

import SwiftUI

struct DestructiveButton: View {
    let title: String
    let icon: String
    var isPrimary: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))

                Text(title)
                    .font(.body.weight(.medium))
            }
            .foregroundColor(isPrimary ? .white : .red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isPrimary ? Color.red : Color.clear,
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isPrimary ? Color.clear : Color.red, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ZStack {
        Color.black
        VStack(spacing: 16) {
            DestructiveButton(title: "Sign Out", icon: "rectangle.portrait.and.arrow.right") {}
            DestructiveButton(title: "Delete Account", icon: "trash", isPrimary: true) {}
        }
        .padding()
    }
}
