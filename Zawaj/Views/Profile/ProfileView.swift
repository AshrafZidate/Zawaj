//
//  ProfileView.swift
//  Zawaj
//
//  Created on 2025-12-21.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator
    @StateObject private var viewModel = ProfileViewModel()
    @State private var selectedTab: ProfileTab = .profile

    enum ProfileTab: String, CaseIterable {
        case profile = "Profile"
        case partners = "Partners"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .profile: return "person.fill"
            case .partners: return "person.2.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()

                switch selectedTab {
                case .profile:
                    ProfileContent(viewModel: viewModel)
                case .partners:
                    ScrollView {
                        VStack(spacing: 24) {
                            PartnersContent(viewModel: viewModel)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .padding(.bottom, 100)
                    }
                case .settings:
                    SettingsContent(viewModel: viewModel, coordinator: coordinator)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("", selection: $selectedTab) {
                        ForEach(ProfileTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 250)
                }
            }
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
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
}

// MARK: - Profile Content

struct ProfileContent: View {
    @ObservedObject var viewModel: ProfileViewModel
    @State private var editingField: EditableField?

    enum EditableField: Identifiable {
        case fullName, username, relationshipStatus, marriageTimeline, topicPriorities

        var id: Self { self }
    }

    var body: some View {
        List {
            // Full Name (Editable)
            ProfileListRow(
                icon: "person.text.rectangle",
                label: "Full Name",
                value: viewModel.currentUser?.fullName ?? "",
                isEditable: true
            )
            .onTapGesture { editingField = .fullName }

            // Username (Editable)
            ProfileListRow(
                icon: "at",
                label: "Username",
                value: viewModel.currentUser?.username ?? "",
                isEditable: true
            )
            .onTapGesture { editingField = .username }

            // Email (Not Editable)
            ProfileListRow(
                icon: "envelope",
                label: "Email",
                value: viewModel.currentUser?.email ?? ""
            )

            // Gender (Not Editable)
            ProfileListRow(
                icon: "person",
                label: "Gender",
                value: viewModel.currentUser?.gender ?? ""
            )

            // Birthday (Not Editable)
            ProfileListRow(
                icon: "calendar",
                label: "Birthday",
                value: formattedBirthday(viewModel.currentUser?.birthday)
            )

            // Relationship Status (Editable)
            ProfileListRow(
                icon: "heart",
                label: "Relationship Status",
                value: viewModel.currentUser?.relationshipStatus ?? "",
                isEditable: true
            )
            .onTapGesture { editingField = .relationshipStatus }

            // Marriage Timeline (Editable)
            ProfileListRow(
                icon: "clock",
                label: "Marriage Timeline",
                value: viewModel.currentUser?.marriageTimeline ?? "",
                isEditable: true
            )
            .onTapGesture { editingField = .marriageTimeline }

            // Answer Preferences (Inline Toggle)
            AnswerPreferenceToggleRow(viewModel: viewModel)

            // Topic Priorities (Editable)
            ProfileListRow(
                icon: "list.star",
                label: "Topic Priorities",
                value: formatTopicPriorities(viewModel.currentUser?.topicPriorities),
                isEditable: true
            )
            .onTapGesture { editingField = .topicPriorities }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .padding(.top, -30)
        .sheet(item: $editingField) { field in
            EditProfileFieldSheet(field: field, viewModel: viewModel)
        }
    }
}

// MARK: - Profile List Row

struct ProfileListRow: View {
    let icon: String
    let label: String
    let value: String
    var isEditable: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))

                Text(value.isEmpty ? "—" : value)
                    .font(.body)
                    .foregroundColor(.white)
            }

            Spacer()

            if isEditable {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .contentShape(Rectangle())
        .listRowBackground(Color.white.opacity(0.1))
        .listRowSeparatorTint(.white.opacity(0.2))
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
    }
}

// MARK: - Answer Preference Toggle Row

struct AnswerPreferenceToggleRow: View {
    @ObservedObject var viewModel: ProfileViewModel
    private let answerOptions = ["Multiple Choice", "Open Ended"]

    private var selectedOption: String {
        viewModel.currentUser?.answerPreference ?? "Multiple Choice"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            labelRow
            toggleButtons
        }
        .listRowBackground(Color.white.opacity(0.1))
        .listRowSeparatorTint(.white.opacity(0.2))
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
    }

    private var labelRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "text.bubble")
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 24)

            Text("Answer Preferences")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }

    private var toggleButtons: some View {
        HStack(spacing: 4) {
            ForEach(answerOptions, id: \.self) { option in
                toggleButton(for: option)
            }
        }
        .padding(4)
        .glassEffect(.clear, in: Capsule())
    }

    @ViewBuilder
    private func toggleButton(for option: String) -> some View {
        let isSelected = selectedOption == option

        Button {
            Task {
                await viewModel.updateProfile(updates: ["answerPreference": option])
            }
        } label: {
            Text(option)
                .font(.subheadline.weight(.medium))
                .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 8)
        }
        .background {
            if isSelected {
                Capsule()
                    .fill(.white.opacity(0.2))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Edit Profile Field Sheet

struct EditProfileFieldSheet: View {
    let field: ProfileContent.EditableField
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss

    @State private var textValue: String = ""
    @State private var selectedOption: String = ""
    @State private var topicPriorities: [String] = []

    // Username validation states
    @State private var isCheckingAvailability: Bool = false
    @State private var isUsernameAvailable: Bool? = nil
    @State private var checkTask: Task<Void, Never>? = nil

    private var title: String {
        switch field {
        case .fullName: return "Full Name"
        case .username: return "Username"
        case .relationshipStatus: return "Relationship Status"
        case .marriageTimeline: return "Marriage Timeline"
        case .topicPriorities: return "Topic Priorities"
        }
    }

    // Username validation
    private var isValidUsernameFormat: Bool {
        let regex = "^[a-zA-Z0-9._-]+$"
        return !textValue.isEmpty &&
               textValue.range(of: regex, options: .regularExpression) != nil
    }

    private var canSaveUsername: Bool {
        // Allow save if username unchanged, or if new username is valid and available
        let originalUsername = viewModel.currentUser?.username ?? ""
        if textValue == originalUsername {
            return true
        }
        return isValidUsernameFormat && isUsernameAvailable == true && !isCheckingAvailability
    }

    private let relationshipOptions = ["Single", "Talking Stage", "Engaged", "Married"]
    private let timelineOptions = ["1-3 Months", "3-6 Months", "6-12 Months", "1-2 Years", "Not sure"]

    @State private var showingPicker: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                GradientBackground()

                if field == .topicPriorities {
                    // Topic priorities needs full height for the List
                    VStack(alignment: .leading, spacing: 0) {
                        topicPrioritiesEditor
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            switch field {
                            case .fullName, .username:
                                textFieldEditor

                            case .relationshipStatus:
                                optionPicker(options: relationshipOptions)

                            case .marriageTimeline:
                                optionPicker(options: timelineOptions)

                            case .topicPriorities:
                                EmptyView()
                            }
                        }
                        .padding(24)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .disabled(field == .username && !canSaveUsername)
                    .opacity(field == .username && !canSaveUsername ? 0.5 : 1)
                }
            }
        }
        .onAppear {
            loadCurrentValue()
        }
    }

    private var textFieldEditor: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(field == .username ? "Change your username" : "Change your full name")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))

            if field == .username {
                // Username field with @ prefix (matching onboarding)
                HStack(spacing: 8) {
                    Text("@")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.leading, 16)

                    TextField("", text: $textValue, prompt: Text("username").foregroundColor(.white.opacity(0.6)))
                        .font(.body)
                        .foregroundColor(.white)
                        .textFieldStyle(.plain)
                        .textContentType(.username)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .onChange(of: textValue) { _, newValue in
                            let originalUsername = viewModel.currentUser?.username ?? ""

                            // Skip check if unchanged
                            if newValue == originalUsername {
                                checkTask?.cancel()
                                isUsernameAvailable = nil
                                isCheckingAvailability = false
                                return
                            }

                            // Cancel previous check
                            checkTask?.cancel()
                            isUsernameAvailable = nil

                            // Only check if format is valid
                            guard !newValue.isEmpty else { return }
                            let regex = "^[a-zA-Z0-9._-]+$"
                            guard newValue.range(of: regex, options: .regularExpression) != nil else { return }

                            // Debounce the availability check
                            checkTask = Task {
                                isCheckingAvailability = true
                                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second debounce

                                guard !Task.isCancelled else { return }

                                let firestoreService = FirestoreService()
                                let available = (try? await firestoreService.isUsernameAvailable(newValue)) ?? false

                                guard !Task.isCancelled else { return }

                                await MainActor.run {
                                    isUsernameAvailable = available
                                    isCheckingAvailability = false
                                }
                            }
                        }

                    // Clear button and status indicator
                    if isCheckingAvailability {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                            .padding(.trailing, 16)
                    } else if let available = isUsernameAvailable {
                        Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(available ? .green : .red)
                            .padding(.trailing, 16)
                    } else if !textValue.isEmpty {
                        Button {
                            textValue = ""
                            isUsernameAvailable = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.trailing, 16)
                    }
                }
                .frame(height: 52)
                .glassEffect(.clear)

                // Username format info and validation feedback
                if !textValue.isEmpty && !isValidUsernameFormat {
                    Text("Username can only contain letters, numbers, and . - _")
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.8))
                } else if isUsernameAvailable == false {
                    Text("This username is already taken")
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.8))
                } else {
                    Text("Letters, numbers, periods, dashes, and underscores only")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
            } else {
                // Full name field (matching onboarding)
                HStack {
                    TextField("", text: $textValue, prompt: Text("Full Name").foregroundColor(.white.opacity(0.6)))
                        .font(.body)
                        .foregroundColor(.white)
                        .textFieldStyle(.plain)
                        .textContentType(.name)
                        .autocapitalization(.words)

                    if !textValue.isEmpty {
                        Button {
                            textValue = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: 52)
                .glassEffect(.clear)
            }
        }
    }

    private func optionPicker(options: [String]) -> some View {
        let pickerTitle = field == .relationshipStatus
            ? "Change your relationship status"
            : "Change your marriage timeline"

        return VStack(alignment: .leading, spacing: 16) {
            Text(pickerTitle)
                .font(.body)
                .foregroundColor(.white.opacity(0.7))

            // Text field that shows current selection and opens picker
            Button {
                showingPicker = true
            } label: {
                HStack {
                    Text(selectedOption.isEmpty ? "Select an option" : selectedOption)
                        .font(.body)
                        .foregroundColor(selectedOption.isEmpty ? .white.opacity(0.6) : .white)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 16)
                .frame(height: 52)
                .glassEffect(.clear)
            }
            .buttonStyle(.plain)

            // Wheel picker
            if showingPicker {
                Picker("", selection: $selectedOption) {
                    ForEach(options, id: \.self) { option in
                        Text(option)
                            .foregroundColor(.white)
                            .tag(option)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 150)
                .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                .onChange(of: selectedOption) { _, _ in
                    // Auto-hide picker after selection with a small delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            showingPicker = false
                        }
                    }
                }
            }
        }
    }

    private var topicPrioritiesEditor: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Rearrange these topics by importance to you")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .padding(.bottom, 24)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(topicPriorities.enumerated()), id: \.element) { index, topic in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.body.weight(.semibold))
                                .foregroundColor(.white.opacity(0.6))
                            Text(topic)
                                .font(.body)
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                        .draggable(topic)
                        .dropDestination(for: String.self) { items, _ in
                            guard let droppedTopic = items.first,
                                  let fromIndex = topicPriorities.firstIndex(of: droppedTopic),
                                  let toIndex = topicPriorities.firstIndex(of: topic) else {
                                return false
                            }
                            withAnimation {
                                topicPriorities.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
                            }
                            return true
                        }
                    }
                }
            }
        }
    }

    // Default topics matching onboarding
    private let defaultTopics = [
        "Religious values",
        "Family expectations",
        "Personality and emotional compatibility",
        "Lifestyle and goals",
        "Finances and career plans",
        "Views on marriage roles",
        "Parenting views",
        "Conflict resolution style"
    ]

    private func loadCurrentValue() {
        guard let user = viewModel.currentUser else { return }

        switch field {
        case .fullName:
            textValue = user.fullName
        case .username:
            textValue = user.username
        case .relationshipStatus:
            selectedOption = user.relationshipStatus
        case .marriageTimeline:
            selectedOption = user.marriageTimeline
        case .topicPriorities:
            // Use user's saved order, or default topics if empty
            if user.topicPriorities.isEmpty {
                topicPriorities = defaultTopics
            } else {
                topicPriorities = user.topicPriorities
            }
        }
    }

    private func saveChanges() {
        Task {
            var updates: [String: Any] = [:]

            switch field {
            case .fullName:
                updates["fullName"] = textValue
            case .username:
                updates["username"] = textValue.lowercased()
            case .relationshipStatus:
                updates["relationshipStatus"] = selectedOption
            case .marriageTimeline:
                updates["marriageTimeline"] = selectedOption
            case .topicPriorities:
                updates["topicPriorities"] = topicPriorities
            }

            await viewModel.updateProfile(updates: updates)
        }
    }
}

// MARK: - Partners Content

struct PartnersContent: View {
    @ObservedObject var viewModel: ProfileViewModel

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
                NoPartnerView(
                    onAddPartner: {
                        viewModel.showingAddPartner = true
                    }
                )
            }

            // Pending Requests
            if !viewModel.pendingPartnerRequests.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pending Requests (\(viewModel.pendingPartnerRequests.count))")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)

                    ForEach(viewModel.pendingPartnerRequests) { request in
                        PendingRequestCard(request: request, viewModel: viewModel)
                    }
                }
            }
        }
    }
}

// MARK: - Settings Content

struct SettingsContent: View {
    @ObservedObject var viewModel: ProfileViewModel
    @ObservedObject var coordinator: OnboardingCoordinator

    var body: some View {
        List {
            // Notification Settings
            Section {
                SettingsListToggle(
                    icon: "bell.badge",
                    title: "Enable Notifications",
                    isOn: $viewModel.notificationsEnabled
                ) { _ in
                    Task {
                        await viewModel.updateNotificationSettings()
                    }
                }
                .listRowSeparatorTint(viewModel.notificationsEnabled ? .white.opacity(0.5) : .white.opacity(0.2))

                if viewModel.notificationsEnabled {
                    SettingsListToggle(
                        icon: "questionmark.circle",
                        title: "Daily Questions",
                        isOn: $viewModel.dailyQuestionNotifications
                    )

                    SettingsListToggle(
                        icon: "person.crop.circle.badge.checkmark",
                        title: "Partner Answered",
                        isOn: $viewModel.partnerAnsweredNotifications
                    )

                    SettingsListToggle(
                        icon: "person.crop.circle.badge.plus",
                        title: "Partner Requests",
                        isOn: $viewModel.partnerRequestNotifications
                    )

                    SettingsListToggle(
                        icon: "clock.badge.exclamationmark",
                        title: "Reminders",
                        isOn: $viewModel.reminderNotifications
                    )

                    SettingsListToggle(
                        icon: "flame",
                        title: "Streak Alerts",
                        isOn: $viewModel.streakNotifications
                    )
                }
            } header: {
                Text("Notifications")
                    .font(.headline)
                    .foregroundColor(.white)
                    .textCase(nil)
            }
            .listRowBackground(Color.white.opacity(0.1))
            .listRowSeparatorTint(.white.opacity(0.2))

            // Account Security
            Section {
                SettingsListButton(icon: "key", title: "Change Password") {
                    viewModel.showingChangePassword = true
                }
            } header: {
                Text("Account Security")
                    .font(.headline)
                    .foregroundColor(.white)
                    .textCase(nil)
            }
            .listRowBackground(Color.white.opacity(0.1))
            .listRowSeparatorTint(.white.opacity(0.2))

            // About & Support
            Section {
                SettingsListRow(icon: "info.circle", title: "App Version", value: "1.0.0")
                SettingsListButton(icon: "envelope", title: "Contact Support") {
                    // TODO: Open email
                }
                SettingsListButton(icon: "doc.text", title: "Privacy Policy") {
                    // TODO: Open privacy policy
                }
                SettingsListButton(icon: "doc.text", title: "Terms of Service") {
                    // TODO: Open terms
                }
            } header: {
                Text("About & Support")
                    .font(.headline)
                    .foregroundColor(.white)
                    .textCase(nil)
            }
            .listRowBackground(Color.white.opacity(0.1))
            .listRowSeparatorTint(.white.opacity(0.2))

            // Sign Out Section
            Section {
                VStack(spacing: 16) {
                    GlassButtonDestructive(title: "Sign Out") {
                        Task {
                            await viewModel.signOut()
                        }
                    }

                    // Developer Mode - Switch Account
                    if DeveloperConfig.isEnabled {
                        GlassButtonPrimary(title: "Switch Account") {
                            viewModel.showingSwitchAccount = true
                        }
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .padding(.top, -30)
        .sheet(isPresented: $viewModel.showingSwitchAccount) {
            SwitchAccountSheet(viewModel: viewModel, coordinator: coordinator)
        }
    }
}

// MARK: - Switch Account Sheet (Developer Mode)

struct SwitchAccountSheet: View {
    @ObservedObject var viewModel: ProfileViewModel
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.dismiss) var dismiss
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ZStack {
                GradientBackground()

                ScrollView {
                    VStack(spacing: 16) {
                        Text("Select an account to switch to:")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 24)

                        ForEach(DeveloperConfig.testAccounts, id: \.email) { account in
                            Button {
                                switchTo(account: account)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(account.name)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text(account.email)
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                .padding(16)
                                .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 24)
                }

                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
            .navigationTitle("Switch Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.18, green: 0.05, blue: 0.35),
                        Color(red: 0.72, green: 0.28, blue: 0.44)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                ),
                for: .navigationBar
            )
        }
    }

    private func switchTo(account: (name: String, email: String, password: String)) {
        isLoading = true
        errorMessage = nil

        Task {
            await viewModel.switchAccount(email: account.email, password: account.password, coordinator: coordinator)

            await MainActor.run {
                isLoading = false
                if viewModel.error == nil {
                    dismiss()
                } else {
                    errorMessage = viewModel.error
                }
            }
        }
    }
}

// MARK: - Settings List Components

struct SettingsListToggle: View {
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
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 24)

            Text(title)
                .font(.body)
                .foregroundColor(.white)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color(red: 0.94, green: 0.26, blue: 0.42))
                .onChange(of: isOn) { _, newValue in
                    onChange?(newValue)
                }
        }
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
    }
}

struct SettingsListButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 24)

                Text(title)
                    .font(.body)
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .buttonStyle(.plain)
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
    }
}

struct SettingsListRow: View {
    let icon: String
    let title: String
    let value: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 24)

            Text(title)
                .font(.body)
                .foregroundColor(.white)

            Spacer()

            if let value = value {
                Text(value)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
        }
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
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
                HStack {
                    TextField("", text: $editedValue)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(.white)
                        .onChange(of: editedValue) { _, newValue in
                            if !newValue.isEmpty {
                                onSave(newValue)
                            }
                        }

                    if !editedValue.isEmpty {
                        Button {
                            editedValue = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
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

// Helper function to format topic priorities
private func formatTopicPriorities(_ priorities: [String]?) -> String {
    guard let priorities = priorities, !priorities.isEmpty else { return "" }
    return priorities.joined(separator: ", ")
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
    @ObservedObject var viewModel: ProfileViewModel

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
                    Task {
                        await viewModel.acceptPartnerRequest(request)
                    }
                }
                .font(.caption.weight(.medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.green, in: RoundedRectangle(cornerRadius: 8))

                Button("Decline") {
                    Task {
                        await viewModel.declinePartnerRequest(request)
                    }
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
        .environmentObject(OnboardingCoordinator())
}
