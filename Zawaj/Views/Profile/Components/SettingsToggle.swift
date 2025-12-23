//
//  SettingsToggle.swift
//  Zawaj
//
//  Created on 2025-12-21.
//

import SwiftUI

struct SettingsToggle: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    let onChange: ((Bool) -> Void)?

    init(icon: String, title: String, isOn: Binding<Bool>, onChange: ((Bool) -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self._isOn = isOn
        self.onChange = onChange
    }

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

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color(red: 0.94, green: 0.26, blue: 0.42))
                .onChange(of: isOn) { oldValue, newValue in
                    onChange?(newValue)
                }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

#Preview {
    ZStack {
        Color.black
        SettingsToggle(icon: "bell.badge", title: "Enable Notifications", isOn: .constant(true))
    }
}
