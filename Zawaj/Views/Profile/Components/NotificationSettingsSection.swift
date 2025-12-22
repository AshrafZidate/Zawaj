//
//  NotificationSettingsSection.swift
//  Zawaj
//
//  Created on 2025-12-21.
//

import SwiftUI

struct NotificationSettingsSection: View {
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        SettingsSection(title: "Notifications") {
            SettingsToggle(
                icon: "bell.badge",
                title: "Enable Notifications",
                isOn: $viewModel.notificationsEnabled
            ) { enabled in
                Task {
                    await viewModel.updateNotificationSettings()
                }
            }

            if viewModel.notificationsEnabled {
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.horizontal, 20)

                SettingsToggle(
                    icon: "questionmark.circle",
                    title: "Daily Questions",
                    isOn: $viewModel.dailyQuestionNotifications
                )

                SettingsToggle(
                    icon: "person.crop.circle.badge.checkmark",
                    title: "Partner Answered",
                    isOn: $viewModel.partnerAnsweredNotifications
                )

                SettingsToggle(
                    icon: "person.crop.circle.badge.plus",
                    title: "Partner Requests",
                    isOn: $viewModel.partnerRequestNotifications
                )

                SettingsToggle(
                    icon: "clock.badge.exclamationmark",
                    title: "Reminders",
                    isOn: $viewModel.reminderNotifications
                )

                SettingsToggle(
                    icon: "flame",
                    title: "Streak Alerts",
                    isOn: $viewModel.streakNotifications
                )
            }
        }
    }
}
