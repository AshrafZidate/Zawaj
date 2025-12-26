//
//  AppPreferencesSection.swift
//  Zawaj
//
//  Created on 2025-12-21.
//

import SwiftUI

struct AppPreferencesSection: View {
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        SettingsSection(title: "Preferences") {
            // Default Answer Format
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 16) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 28)

                    Text("Default Answer Format")
                        .font(.body)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Picker("", selection: $viewModel.defaultAnswerFormat) {
                    Text("Open Ended").tag(LegacyQuestionType.openEnded)
                    Text("Multiple Choice").tag(LegacyQuestionType.multipleChoice)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
    }
}
