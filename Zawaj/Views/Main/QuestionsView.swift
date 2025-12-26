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

    // Partners ordered by connection order (who they partnered with first)
    private var sortedPartners: [User] {
        viewModel.partners
    }

    private var currentPartnerIndex: Int {
        guard let selectedId = selectedPartnerId else { return 0 }
        return sortedPartners.firstIndex(where: { $0.id == selectedId }) ?? 0
    }

    var body: some View {
        VStack(spacing: 0) {
            // Page indicator dots
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
        .onChange(of: selectedPartnerForQuestions) { _, partner in
            if let partner = partner {
                selectedPartnerId = partner.id
                tabViewId = UUID()
                selectedPartnerForQuestions = nil
            }
        }
        .sheet(item: $selectedPartnerForReveal) { partner in
            if let question = viewModel.todayQuestion {
                AnswerRevealSheet(
                    viewModel: viewModel,
                    question: question,
                    partner: partner
                )
            }
        }
    }
}

// MARK: - Partner Question Page

struct PartnerQuestionPage: View {
    @ObservedObject var viewModel: DashboardViewModel
    let partner: User
    let onViewAnswer: () -> Void

    private var partnerAnswered: Bool {
        viewModel.partnerAnswers[partner.id] ?? false
    }

    private var status: PartnerAnswerStatus {
        PartnerAnswerStatus.determine(userAnswered: viewModel.userAnswered, partnerAnswered: partnerAnswered)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Partner Header
                VStack(spacing: 8) {
                    Text(partner.fullName)
                        .font(.title2.weight(.bold))
                        .foregroundColor(.white)

                    if let question = viewModel.todayQuestion {
                        Text(question.topic)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.top, 32)

                // Question Card
                if let question = viewModel.todayQuestion {
                    QuestionCard(question: question)
                }

                // Status-based content
                switch status {
                case .reviewAnswers:
                    // Both answered - show review button
                    ReviewReadyView(partner: partner, onViewAnswer: onViewAnswer)

                case .waitingForPartner:
                    // User answered, waiting for partner
                    WaitingForPartnerView(partner: partner)

                case .answerToUnlock, .answerBoth:
                    // User needs to answer
                    if let question = viewModel.todayQuestion {
                        AnswerInputSection(
                            question: question,
                            onSubmit: { answer in
                                Task {
                                    await viewModel.submitAnswer(questionId: question.id, answerText: answer)
                                }
                            }
                        )
                    }

                case .newQuestionsTomorrow:
                    // All done for today
                    NewQuestionsTomorrowView()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Review Ready View

struct ReviewReadyView: View {
    let partner: User
    let onViewAnswer: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("Both answered!")
                .font(.title3.weight(.semibold))
                .foregroundColor(.white)

            Text("See how \(partner.fullName.split(separator: " ").first.map(String.init) ?? partner.fullName) answered")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            GlassButtonPrimary(title: "View Answers") {
                onViewAnswer()
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Waiting For Partner View

struct WaitingForPartnerView: View {
    let partner: User

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Waiting for \(partner.fullName.split(separator: " ").first.map(String.init) ?? partner.fullName)")
                .font(.title3.weight(.semibold))
                .foregroundColor(.white)

            Text("You've answered! We'll notify you when they respond.")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - New Questions Tomorrow View

struct NewQuestionsTomorrowView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 60))
                .foregroundColor(.purple)

            Text("All done for today!")
                .font(.title3.weight(.semibold))
                .foregroundColor(.white)

            Text("New questions will be available tomorrow.")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Answer Reveal Sheet

struct AnswerRevealSheet: View {
    @ObservedObject var viewModel: DashboardViewModel
    let question: DailyQuestion
    let partner: User
    @State private var userAnswer: String = ""
    @State private var partnerAnswer: String = ""
    @State private var isLoading: Bool = true
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            } else {
                AnswerRevealView(
                    question: question,
                    partner: partner,
                    userAnswer: userAnswer,
                    partnerAnswer: partnerAnswer
                )
            }
        }
        .onAppear {
            Task {
                let answers = await viewModel.getAnswers(for: question.id)
                await MainActor.run {
                    userAnswer = answers.userAnswer ?? ""
                    partnerAnswer = answers.partnerAnswers[partner.id] ?? ""
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Question Card

struct QuestionCard: View {
    let question: DailyQuestion

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(question.questionText)
                .font(.title3.weight(.semibold))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)

            if question.questionType == .multipleChoice, let options = question.options {
                VStack(spacing: 8) {
                    ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                        HStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 8, height: 8)

                            Text(option)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Partner Question Status Card

struct PartnerQuestionStatusCard: View {
    let partner: User
    let userAnswered: Bool
    let partnerAnswered: Bool
    let onAnswerQuestion: () -> Void
    let onViewAnswer: () -> Void

    private var status: PartnerAnswerStatus {
        PartnerAnswerStatus.determine(userAnswered: userAnswered, partnerAnswered: partnerAnswered)
    }

    var body: some View {
        Button(action: {
            if status == .reviewAnswers {
                onViewAnswer()
            } else {
                onAnswerQuestion()
            }
        }) {
            HStack(spacing: 12) {
                // Partner initial
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(partner.fullName.prefix(1)))
                            .font(.headline)
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(partner.fullName.split(separator: " ").first.map(String.init) ?? "")
                        .font(.body.weight(.medium))
                        .foregroundColor(.white)

                    HStack(spacing: 4) {
                        Image(systemName: status.icon)
                            .font(.caption2)
                            .foregroundColor(status.iconColor)

                        Text(status.message)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(12)
            .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 24)
    }
}

// MARK: - Answer Input Section

struct AnswerInputSection: View {
    let question: DailyQuestion
    let onSubmit: (String) -> Void

    @State private var answerText: String = ""
    @State private var selectedOption: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Answer")
                .font(.headline)
                .foregroundColor(.white)

            if question.questionType == .openEnded {
                // Open-ended text input
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
            } else if question.questionType == .multipleChoice, let options = question.options {
                // Multiple choice selection
                VStack(spacing: 12) {
                    ForEach(options, id: \.self) { option in
                        Button(action: {
                            selectedOption = option
                        }) {
                            HStack {
                                Circle()
                                    .fill(selectedOption == option ? Color(red: 0.94, green: 0.26, blue: 0.42) : Color.white.opacity(0.2))
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                    )

                                Text(option)
                                    .font(.body)
                                    .foregroundColor(.white)

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

            // Submit Button
            GlassButtonPrimary(title: "Submit Answer") {
                let answer = question.questionType == .openEnded ? answerText : (selectedOption ?? "")
                if !answer.isEmpty {
                    onSubmit(answer)
                }
            }
            .disabled(!canSubmit)
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var canSubmit: Bool {
        if question.questionType == .openEnded {
            return !answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } else {
            return selectedOption != nil
        }
    }
}

// MARK: - Waiting for Partners View

struct WaitingForPartnersView: View {
    let partners: [User]
    let partnerAnswers: [String: Bool]

    private var partnersWhoAnswered: Int {
        partnerAnswers.values.filter { $0 }.count
    }

    private var allPartnersAnswered: Bool {
        !partners.isEmpty && partnersWhoAnswered == partners.count
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: allPartnersAnswered ? "checkmark.circle.fill" : "clock.fill")
                .font(.system(size: 60))
                .foregroundColor(allPartnersAnswered ? .green : .blue)

            Text(allPartnersAnswered ? "All partners answered!" : "Waiting for partners")
                .font(.title3.weight(.semibold))
                .foregroundColor(.white)

            Text(allPartnersAnswered ?
                 "Tap on a partner above to see their answer" :
                 "\(partnersWhoAnswered)/\(partners.count) partners have answered"
            )
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ZStack {
        GradientBackground()
        QuestionsView(viewModel: DashboardViewModel(), selectedPartnerForQuestions: .constant(nil))
    }
}
