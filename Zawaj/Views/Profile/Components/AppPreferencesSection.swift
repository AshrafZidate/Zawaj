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
        SettingsSection(title: "App Preferences") {
            // Theme Picker
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 16) {
                    Image(systemName: "moon.stars")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 28)

                    Text("Theme")
                        .font(.body)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Picker("", selection: $viewModel.selectedTheme) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }

            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.horizontal, 20)

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
                    Text("Open Ended").tag(QuestionType.openEnded)
                    Text("Multiple Choice").tag(QuestionType.multipleChoice)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
    }
}
