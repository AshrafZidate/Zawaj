//
//  ProfileView.swift
//  Zawaj
//
//  Created on 2025-12-21.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var selectedTab: ProfileTab = .profile

    enum ProfileTab: String, CaseIterable {
        case profile = "Profile"
        case partners = "Partners"
        case settings = "Settings"
    }

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: 0) {
                // Top Navigation Bar
                ProfileNavigationBar(selectedTab: $selectedTab)
                    .padding(.top, 8)

                // Content based on selected tab
                ScrollView {
                    VStack(spacing: 24) {
                        switch selectedTab {
                        case .profile:
                            ProfileContent(viewModel: viewModel)
                        case .partners:
                            PartnersContent(viewModel: viewModel)
                        case .settings:
                            SettingsContent(viewModel: viewModel)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 100)
                }
            }
        }
        .alert("Disconnect Partner", isPresented: $viewModel.showingDisconnectPartnerAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Disconnect", role: .destructive) {
                Task {
                    await viewModel.disconnectPartner()
                }
            }
        } message: {
            Text("Are you sure you want to disconnect from your partner? You can always reconnect later.")
        }
        .sheet(isPresented: $viewModel.showingAddPartner) {
            AddPartnerView()
        }
        .sheet(isPresented: $viewModel.showingChangePassword) {
            ChangePasswordView(viewModel: viewModel)
        }
        .onAppear {
            Task {
                await viewModel.loadProfileData()
            }
        }
    }
}

// MARK: - Profile Navigation Bar

struct ProfileNavigationBar: View {
    @Binding var selectedTab: ProfileView.ProfileTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ProfileView.ProfileTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    Text(tab.rawValue)
                        .font(.body.weight(selectedTab == tab ? .semibold : .regular))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selectedTab == tab ?
                            Color.white.opacity(0.2) :
                            Color.clear
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 24)
    }
}

// MARK: - Profile Content

struct ProfileContent: View {
    @ObservedObject var viewModel: ProfileViewModel
    @State private var isEditing = false

    var body: some View {
        VStack(spacing: 24) {
            // Editable Profile Information
            VStack(spacing: 16) {
                EditableProfileField(
                    label: "Full Name",
                    value: viewModel.currentUser?.fullName ?? "",
                    isEditing: isEditing,
                    onSave: { newValue in
                        Task {
                            await viewModel.updateProfile(updates: ["fullName": newValue])
                        }
                    }
                )

                EditableProfileField(
                    label: "Username",
                    value: "@\(viewModel.currentUser?.username ?? "")",
                    isEditing: isEditing,
                    onSave: { newValue in
                        Task {
                            // Remove @ prefix if user included it
                            let username = newValue.hasPrefix("@") ? String(newValue.dropFirst()) : newValue
                            await viewModel.updateProfile(updates: ["username": username])
                        }
                    }
                )

                // Email (Read-only)
                ProfileInfoRow(
                    label: "Email",
                    value: viewModel.currentUser?.email ?? "",
                    icon: "envelope"
                )

                // Gender (Read-only)
                ProfileInfoRow(
                    label: "Gender",
                    value: viewModel.currentUser?.gender ?? "",
                    icon: "person"
                )

                // Birthday with DatePicker
                if isEditing {
                    DatePickerProfileField(
                        label: "Birthday",
                        selection: Binding(
                            get: { viewModel.currentUser?.birthday ?? Date() },
                            set: { newValue in
                                Task {
                                    await viewModel.updateProfile(updates: ["birthday": newValue])
                                }
                            }
                        )
                    )
                } else {
                    ProfileInfoRow(
                        label: "Birthday",
                        value: formattedBirthday(viewModel.currentUser?.birthday),
                        icon: "calendar"
                    )
                }

                // Relationship Status with Picker
                if isEditing {
                    PickerProfileField(
                        label: "Relationship Status",
                        selection: Binding(
                            get: { viewModel.currentUser?.relationshipStatus ?? "Single" },
                            set: { newValue in
                                Task {
                                    await viewModel.updateProfile(updates: ["relationshipStatus": newValue])
                                }
                            }
                        ),
                        options: ["Single", "Talking Stage", "Engaged", "Married"]
                    )
                } else {
                    ProfileInfoRow(
                        label: "Relationship Status",
                        value: viewModel.currentUser?.relationshipStatus ?? "",
                        icon: "heart"
                    )
                }

                // Marriage Timeline with Picker
                if isEditing {
                    PickerProfileField(
                        label: "Marriage Timeline",
                        selection: Binding(
                            get: { viewModel.currentUser?.marriageTimeline ?? "1-3 Months" },
                            set: { newValue in
                                Task {
                                    await viewModel.updateProfile(updates: ["marriageTimeline": newValue])
                                }
                            }
                        ),
                        options: ["1-3 Months", "3-6 Months", "6-12 Months", "1-2 Years", "Not sure"]
                    )
                } else {
                    ProfileInfoRow(
                        label: "Marriage Timeline",
                        value: viewModel.currentUser?.marriageTimeline ?? "",
                        icon: "clock"
                    )
                }

                // Topic Priorities
                if let priorities = viewModel.currentUser?.topicPriorities, !priorities.isEmpty {
                    if isEditing {
                        TopicPrioritiesEditor(
                            priorities: Binding(
                                get: { viewModel.currentUser?.topicPriorities ?? [] },
                                set: { newValue in
                                    Task {
                                        await viewModel.updateProfile(updates: ["topicPriorities": newValue])
                                    }
                                }
                            )
                        )
                    } else {
                        ProfileInfoRow(
                            label: "Topic Priorities",
                            value: "\(priorities.count) topics ordered",
                            icon: "list.star"
                        )
                    }
                }
            }
            .padding(20)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))

            // Default Answer Format
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
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
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))

            // Edit/Save Button
            Button(action: { isEditing.toggle() }) {
                Text(isEditing ? "Done Editing" : "Edit Profile")
                    .font(.body.weight(.medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Color(red: 0.94, green: 0.26, blue: 0.42),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Partners Content

struct PartnersContent: View {
    @ObservedObject var viewModel: ProfileViewModel

    // Share content for invite
    private let inviteMessage = "Download the Zawāj app so we can get to know each other better for marriage! 💍"
    private let appStoreLink = "https://apps.apple.com/app/zawaj"

    private var shareContent: String {
        return "\(inviteMessage)\n\n\(appStoreLink)"
    }

    var body: some View {
        VStack(spacing: 24) {
            // Current Partners Section
            if let partner = viewModel.partner {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Connected Partners")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)

                    ProfilePartnerCard(partner: partner) {
                        viewModel.showingDisconnectPartnerAlert = true
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.4))

                    Text("No Partners Connected")
                        .font(.title3.weight(.medium))
                        .foregroundColor(.white)

                    Text("Connect with someone to start answering questions together")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                    // Action Buttons
                    VStack(spacing: 16) {
                        // Add Zawaj Partner Button
                        Button(action: {
                            viewModel.showingAddPartner = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 18, weight: .medium))

                                Text("Add a Zawāj partner")
                                    .font(.body.weight(.medium))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Invite Partner Button with ShareLink
                        ShareLink(
                            item: shareContent,
                            subject: Text("Join me on Zawāj"),
                            message: Text(inviteMessage)
                        ) {
                            HStack(spacing: 12) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 18, weight: .medium))

                                Text("Invite a partner to Zawāj")
                                    .font(.body.weight(.medium))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.top, 8)
                }
                .padding(.vertical, 40)
            }

            // Pending Requests
            if !viewModel.pendingPartnerRequests.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pending Requests (\(viewModel.pendingPartnerRequests.count))")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)

                    ForEach(viewModel.pendingPartnerRequests) { request in
                        PendingRequestCard(request: request)
                    }
                }
            }
        }
    }
}

// MARK: - Settings Content

struct SettingsContent: View {
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        VStack(spacing: 24) {
            // Notification Settings
            SettingsSection(title: "Notifications") {
                SettingsToggle(
                    icon: "bell.badge",
                    title: "Enable Notifications",
                    isOn: $viewModel.notificationsEnabled
                ) { _ in
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

            // Account Security
            SettingsSection(title: "Account Security") {
                SettingsButton(icon: "key", title: "Change Password") {
                    viewModel.showingChangePassword = true
                }
            }

            // About & Support
            SettingsSection(title: "About & Support") {
                SettingsRow(icon: "info.circle", title: "App Version", value: "1.0.0")
                SettingsButton(icon: "questionmark.circle", title: "Help & FAQ") {
                    // TODO: Navigate to help
                }
                SettingsButton(icon: "envelope", title: "Contact Support") {
                    // TODO: Open email
                }
                SettingsButton(icon: "doc.text", title: "Privacy Policy") {
                    // TODO: Open privacy policy
                }
                SettingsButton(icon: "doc.text", title: "Terms of Service") {
                    // TODO: Open terms
                }
            }

            // Sign Out Button
            GlassButtonDestructive(title: "Sign Out") {
                Task {
                    await viewModel.signOut()
                }
            }
        }
    }
}

// MARK: - Supporting Components

struct ProfileInfoRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))

                Text(label)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }

            Text(value)
                .font(.body)
                .foregroundColor(.white)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct EditableProfileField: View {
    let label: String
    let value: String
    let isEditing: Bool
    let onSave: (String) -> Void

    @State private var editedValue: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))

            if isEditing {
                TextField("", text: $editedValue)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                    .onChange(of: editedValue) { _, newValue in
                        if !newValue.isEmpty {
                            onSave(newValue)
                        }
                    }
            } else {
                Text(value)
                    .font(.body)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .onAppear {
            editedValue = value
        }
    }
}

struct PickerProfileField: View {
    let label: String
    @Binding var selection: String
    let options: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))

            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) {
                        selection = option
                    }
                }
            } label: {
                HStack {
                    Text(selection)
                        .font(.body)
                        .foregroundColor(.white)

                    Spacer()

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding()
                .background(Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

struct DatePickerProfileField: View {
    let label: String
    @Binding var selection: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))

            DatePicker(
                "",
                selection: $selection,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .tint(.blue)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

// Helper function to format birthday
private func formattedBirthday(_ date: Date?) -> String {
    guard let date = date else { return "" }
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: date)
}

struct ProfilePartnerCard: View {
    let partner: User
    let onDisconnect: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Initials Badge
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(partner.fullName.prefix(2).uppercased()))
                            .font(.headline)
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(partner.fullName)
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("@\(partner.username)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                Button("Disconnect") {
                    onDisconnect()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct PendingRequestCard: View {
    let request: PartnerRequest

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("@\(request.senderUsername)")
                    .font(.body.weight(.medium))
                    .foregroundColor(.white)

                Text("Sent \(request.createdAt, style: .relative) ago")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            HStack(spacing: 12) {
                Button("Accept") {
                    // TODO: Accept request
                }
                .font(.caption.weight(.medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.green, in: RoundedRectangle(cornerRadius: 8))

                Button("Decline") {
                    // TODO: Decline request
                }
                .font(.caption.weight(.medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.8), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct TopicPrioritiesEditor: View {
    @Binding var priorities: [String]
    @State private var editablePriorities: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "list.star")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))

                Text("Topic Priorities")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }

            VStack(spacing: 8) {
                ForEach(Array(editablePriorities.enumerated()), id: \.offset) { index, topic in
                    HStack(spacing: 12) {
                        // Drag handle
                        Image(systemName: "line.3.horizontal")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.4))

                        // Number indicator
                        Text("\(index + 1)")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 20)

                        // Topic text
                        Text(topic)
                            .font(.subheadline)
                            .foregroundColor(.white)

                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }
                .onMove { source, destination in
                    editablePriorities.move(fromOffsets: source, toOffset: destination)
                    priorities = editablePriorities
                }
            }

            Text("Drag to reorder")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
                .padding(.top, 4)
        }
        .padding()
        .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .onAppear {
            editablePriorities = priorities
        }
    }
}

#Preview {
    ProfileView()
}
