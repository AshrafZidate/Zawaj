//
//  SettingsRow.swift
//  Zawaj
//
//  Created on 2025-12-21.
//

import SwiftUI

struct SettingsRow: View {
    let icon: String
    let title: String
    let value: String?

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 28)

            Text(title)
                .font(.body)
                .foregroundColor(.white)

            Spacer()

            if let value = value {
                Text(value)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

#Preview {
    ZStack {
        Color.black
        SettingsRow(icon: "envelope", title: "Email", value: "ashraf@example.com")
    }
}
