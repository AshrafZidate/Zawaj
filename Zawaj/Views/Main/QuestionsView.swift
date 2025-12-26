//
//  QuestionsView.swift
//  Zawaj
//
//  Created on 2025-12-22.
//

import SwiftUI

struct QuestionsView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Binding var selectedPartnerForQuestions: User?
    @State private var selectedPartnerId: String?
    @State private var selectedPartnerForReveal: User?
    @State private var tabViewId: UUID = UUID()

    private var sortedPartners: [User] {
        viewModel.partners
    }

    var body: some View {
        VStack(spacing: 0) {
            // Page indicator dots for multiple partners
            if sortedPartners.count > 1 {
                HStack(spacing: 8) {
                    ForEach(sortedPartners) { partner in
                        Circle()
                            .fill(partner.id == selectedPartnerId ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 8)
            }

            // Paged partner content
            TabView(selection: $selectedPartnerId) {
                ForEach(sortedPartners) { partner in
                    PartnerQuestionPage(
                        viewModel: viewModel,
                        partner: partner,
                        onViewAnswer: {
                            selectedPartnerForReveal = partner
                        }
                    )
                    .tag(partner.id as String?)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .id(tabViewId)
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            if selectedPartnerId == nil, let firstPartner = sortedPartners.first {
                selectedPartnerId = firstPartner.id
            }
        }
        .onChange(of: selectedPartnerId) { _, newPartnerId in
            if let partnerId = newPartnerId,
               let partner = sortedPartners.first(where: { $0.id == partnerId }) {
                Task {
                    await viewModel.selectPartner(partner)
                }
            }
        }
        .onChange(of: selectedPartnerForQuestions) { _, partner in
            if let partner = partner {
                selectedPartnerId = partner.id
                tabViewId = UUID()
                selectedPartnerForQuestions = nil
            }
        }
        .sheet(item: $selectedPartnerForReveal) { partner in
            AnswersReviewSheet(viewModel: viewModel, partner: partner)
        }
    }
}

// MARK: - Partner Question Page

struct PartnerQuestionPage: View {
    @ObservedObject var viewModel: DashboardViewModel
    let partner: User
    let onViewAnswer: () -> Void

    private var hasPartnerAnsweredCurrentQuestion: Bool {
        guard let question = viewModel.currentQuestion else { return false }
        return viewModel.partnerAnswers[question.id] != nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with partner name and topic info
                QuestionHeader(
                    partnerName: partner.fullName,
                    topicName: viewModel.todayTopic?.name,
                    subtopicName: viewModel.todaySubtopic?.name,
                    progressText: viewModel.progressText
                )

                // Main content based on state
                if viewModel.isPartnershipComplete {
                    PartnershipCompleteView()
                } else if viewModel.isAllQuestionsComplete {
                    AllQuestionsCompleteView(
                        partner: partner,
                        hasPartnerAnswered: !viewModel.partnerAnswers.isEmpty,
                        onViewAnswers: onViewAnswer,
                        canRemindPartner: viewModel.canRemindPartner,
                        isRemindingPartner: viewModel.isRemindingPartner,
                        reminderCooldownMinutes: viewModel.reminderCooldownMinutes,
                        onRemindPartner: {
                            Task {
                                await viewModel.remindPartner()
                            }
                        }
                    )
                    .task {
                        await viewModel.checkReminderCooldown()
                    }
                } else if let question = viewModel.currentQuestion {
                    // Show current question
                    QuestionCardNew(question: question)

                    // Answer input section
                    AnswerInputSectionNew(
                        question: question,
                        userPreference: viewModel.currentUser?.answerPreference ?? "choice",
                        onSubmit: { answerText, selectedOptions in
                            Task {
                                await viewModel.submitAnswer(
                                    answerText: answerText,
                                    selectedOptions: selectedOptions
                                )
                            }
                        }
                    )
                } else {
                    // Loading or no questions state
                    LoadingQuestionsView()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Question Header

struct QuestionHeader: View {
    let partnerName: String
    let topicName: String?
    let subtopicName: String?
    let progressText: String

    var body: some View {
        VStack(spacing: 8) {
            Text(partnerName)
                .font(.title2.weight(.bold))
                .foregroundColor(.white)

            if let topic = topicName {
                Text(topic)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white.opacity(0.8))
            }

            if let subtopic = subtopicName {
                Text(subtopic)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }

            if !progressText.isEmpty {
                Text("Question \(progressText)")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.top, 4)
            }
        }
        .padding(.top, 32)
    }
}

// MARK: - Question Card (New)

struct QuestionCardNew: View {
    let question: Question

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Question type badge
            HStack {
                Text(question.questionType == .singleChoice ? "Choose one" : "Select all that apply")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.1), in: Capsule())

                Spacer()
            }

            Text(question.questionText)
                .font(.title3.weight(.semibold))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Answer Input Section (New)

struct AnswerInputSectionNew: View {
    let question: Question
    let userPreference: String  // "open-ended" or "multiple-choice"
    let onSubmit: (String, [String]?) -> Void

    @State private var answerText: String = ""
    @State private var selectedOption: String? = nil
    @State private var selectedOptions: Set<String> = []
    @State private var useOpenEnded: Bool = false

    // Determine display mode based on question type and user preference
    // singleChoice: Always radio buttons (pick one)
    // multiChoice + open-ended pref: Free text
    // multiChoice + multiple-choice pref: Checkboxes (pick multiple), can toggle to free text
    // openEnded + open-ended pref: Free text
    // openEnded + multiple-choice pref: Radio buttons (pick one), can toggle to free text
    private var displayMode: AnswerDisplayMode {
        switch question.questionType {
        case .singleChoice:
            // Always radio buttons, no toggle
            return .singleChoice
        case .multiChoice:
            if userPreference == "open-ended" {
                return .openEnded
            } else {
                return useOpenEnded ? .openEnded : .multiChoice
            }
        case .openEnded:
            if userPreference == "open-ended" {
                return .openEnded
            } else {
                return useOpenEnded ? .openEnded : .singleChoice
            }
        }
    }

    // Whether to show the toggle button
    private var showToggle: Bool {
        switch question.questionType {
        case .singleChoice:
            return false  // singleChoice never has toggle
        case .multiChoice:
            return userPreference != "open-ended"  // Can toggle if pref is multiple-choice
        case .openEnded:
            return userPreference != "open-ended"  // Can toggle if pref is multiple-choice
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with optional toggle
            if showToggle {
                HStack {
                    Text("Your Answer")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: {
                        useOpenEnded.toggle()
                        // Clear selections when toggling
                        selectedOptions.removeAll()
                        selectedOption = nil
                        answerText = ""
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: useOpenEnded ? "list.bullet" : "text.alignleft")
                                .font(.caption)
                            Text(useOpenEnded ? "Show options" : "Write freely")
                                .font(.caption)
                        }
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.1), in: Capsule())
                    }
                }
            } else {
                Text("Your Answer")
                    .font(.headline)
                    .foregroundColor(.white)
            }

            // Input based on display mode
            switch displayMode {
            case .openEnded:
                OpenEndedInput(answerText: $answerText)
            case .singleChoice:
                SingleChoiceInput(
                    options: question.options ?? [],
                    selectedOption: $selectedOption
                )
            case .multiChoice:
                MultiChoiceInput(
                    options: question.options ?? [],
                    selectedOptions: $selectedOptions
                )
            }

            // Submit Button
            GlassButtonPrimary(title: "Submit Answer") {
                submitAnswer()
            }
            .disabled(!canSubmit)
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var canSubmit: Bool {
        switch displayMode {
        case .openEnded:
            return !answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .singleChoice:
            return selectedOption != nil
        case .multiChoice:
            return !selectedOptions.isEmpty
        }
    }

    private func submitAnswer() {
        switch displayMode {
        case .openEnded:
            onSubmit(answerText.trimmingCharacters(in: .whitespacesAndNewlines), nil)
        case .singleChoice:
            if let option = selectedOption {
                onSubmit(option, [option])
            }
        case .multiChoice:
            let optionsArray = Array(selectedOptions)
            onSubmit(optionsArray.joined(separator: ", "), optionsArray)
        }
    }
}

// Display mode for answer input
enum AnswerDisplayMode {
    case openEnded      // Free text input
    case singleChoice   // Radio buttons (pick one)
    case multiChoice    // Checkboxes (pick multiple)
}

// MARK: - Open Ended Input

struct OpenEndedInput: View {
    @Binding var answerText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextEditor(text: $answerText)
                .frame(minHeight: 120)
                .padding(12)
                .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)

            Text("\(answerText.count)/500")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

// MARK: - Single Choice Input

struct SingleChoiceInput: View {
    let options: [String]
    @Binding var selectedOption: String?

    var body: some View {
        VStack(spacing: 12) {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    selectedOption = option
                }) {
                    HStack {
                        Circle()
                            .fill(selectedOption == option ? Color(red: 0.94, green: 0.26, blue: 0.42) : Color.clear)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(selectedOption == option ? Color(red: 0.94, green: 0.26, blue: 0.42) : Color.white.opacity(0.4), lineWidth: 2)
                            )

                        Text(option)
                            .font(.body)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)

                        Spacer()
                    }
                    .padding(16)
                    .background(
                        selectedOption == option ?
                        Color.white.opacity(0.15) : Color.white.opacity(0.05),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Multi Choice Input

struct MultiChoiceInput: View {
    let options: [String]
    @Binding var selectedOptions: Set<String>

    var body: some View {
        VStack(spacing: 12) {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    if selectedOptions.contains(option) {
                        selectedOptions.remove(option)
                    } else {
                        selectedOptions.insert(option)
                    }
                }) {
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(selectedOptions.contains(option) ? Color(red: 0.94, green: 0.26, blue: 0.42) : Color.clear)
                            .frame(width: 20, height: 20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(selectedOptions.contains(option) ? Color(red: 0.94, green: 0.26, blue: 0.42) : Color.white.opacity(0.4), lineWidth: 2)
                            )
                            .overlay(
                                selectedOptions.contains(option) ?
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(.white)
                                : nil
                            )

                        Text(option)
                            .font(.body)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)

                        Spacer()
                    }
                    .padding(16)
                    .background(
                        selectedOptions.contains(option) ?
                        Color.white.opacity(0.15) : Color.white.opacity(0.05),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - All Questions Complete View

struct AllQuestionsCompleteView: View {
    let partner: User
    let hasPartnerAnswered: Bool
    let onViewAnswers: () -> Void
    let canRemindPartner: Bool
    let isRemindingPartner: Bool
    let reminderCooldownMinutes: Int
    let onRemindPartner: () -> Void

    private var partnerFirstName: String {
        partner.fullName.split(separator: " ").first.map(String.init) ?? partner.fullName
    }

    private var cooldownText: String {
        if reminderCooldownMinutes >= 60 {
            let hours = reminderCooldownMinutes / 60
            let minutes = reminderCooldownMinutes % 60
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            }
            return "\(hours)h"
        }
        return "\(reminderCooldownMinutes)m"
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: hasPartnerAnswered ? "checkmark.circle.fill" : "clock.fill")
                .font(.system(size: 60))
                .foregroundColor(hasPartnerAnswered ? .green : .blue)

            Text(hasPartnerAnswered ? "Both answered!" : "You've finished!")
                .font(.title3.weight(.semibold))
                .foregroundColor(.white)

            Text(hasPartnerAnswered ?
                 "See how \(partnerFirstName) answered" :
                 "Waiting for \(partnerFirstName) to complete")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            if hasPartnerAnswered {
                GlassButtonPrimary(title: "View Answers") {
                    onViewAnswers()
                }
                .padding(.top, 8)
            } else {
                // Remind partner button
                VStack(spacing: 8) {
                    Button(action: onRemindPartner) {
                        HStack(spacing: 8) {
                            if isRemindingPartner {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "bell.badge")
                            }
                            Text(isRemindingPartner ? "Sending..." : "Remind \(partnerFirstName)")
                        }
                        .font(.body.weight(.medium))
                        .foregroundColor(canRemindPartner ? .white : .white.opacity(0.5))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            canRemindPartner ?
                            Color.white.opacity(0.2) : Color.white.opacity(0.1),
                            in: Capsule()
                        )
                    }
                    .disabled(!canRemindPartner || isRemindingPartner)

                    if !canRemindPartner && reminderCooldownMinutes > 0 {
                        Text("Available again in \(cooldownText)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Partnership Complete View

struct PartnershipCompleteView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)

            Text("All Done!")
                .font(.title3.weight(.semibold))
                .foregroundColor(.white)

            Text("You've completed all the questions with this partner. Check the Archives to review past answers.")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Loading Questions View

struct LoadingQuestionsView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.2)

            Text("Loading questions...")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Answers Review Sheet

struct AnswersReviewSheet: View {
    @ObservedObject var viewModel: DashboardViewModel
    let partner: User
    @Environment(\.dismiss) var dismiss

    /// Questions to show in review - all questions where at least one person answered
    private var questionsToShow: [Question] {
        viewModel.allSubtopicQuestions.filter { question in
            viewModel.userAnswers[question.id] != nil || viewModel.partnerAnswers[question.id] != nil
        }
    }

    var body: some View {
        ZStack {
            GradientBackground()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.7))
                        }

                        Spacer()

                        Text("Answers Review")
                            .font(.headline)
                            .foregroundColor(.white)

                        Spacer()

                        // Spacer for balance
                        Color.clear.frame(width: 28, height: 28)
                    }
                    .padding(.top, 8)

                    // Topic/Subtopic info
                    if let topic = viewModel.todayTopic, let subtopic = viewModel.todaySubtopic {
                        VStack(spacing: 4) {
                            Text(topic.name)
                                .font(.title3.weight(.semibold))
                                .foregroundColor(.white)

                            Text(subtopic.name)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }

                    // Questions and answers - show all questions where at least one person answered
                    ForEach(questionsToShow) { question in
                        AnswerComparisonCard(
                            question: question,
                            userAnswer: viewModel.userAnswers[question.id],
                            partnerAnswer: viewModel.partnerAnswers[question.id],
                            partnerName: partner.fullName
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Answer Comparison Card

struct AnswerComparisonCard: View {
    let question: Question
    let userAnswer: Answer?
    let partnerAnswer: Answer?
    let partnerName: String

    private var partnerFirstName: String {
        partnerName.split(separator: " ").first.map(String.init) ?? partnerName
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Question
            Text(question.questionText)
                .font(.headline)
                .foregroundColor(.white)

            // Your answer
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(Color(red: 0.94, green: 0.26, blue: 0.42))
                    Text("Your answer")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white.opacity(0.8))
                }

                if let answer = userAnswer {
                    Text(answer.answerText)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                } else {
                    Text("Not answered yet")
                        .font(.body.italic())
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            Divider()
                .background(Color.white.opacity(0.2))

            // Partner's answer
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "person.circle")
                        .foregroundColor(.blue)
                    Text("\(partnerFirstName)'s answer")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white.opacity(0.8))
                }

                if let answer = partnerAnswer {
                    Text(answer.answerText)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                } else {
                    Text("Not answered yet")
                        .font(.body.italic())
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ZStack {
        GradientBackground()
        QuestionsView(viewModel: DashboardViewModel(), selectedPartnerForQuestions: .constant(nil))
    }
}
