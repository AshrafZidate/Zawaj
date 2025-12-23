//
//  QuestionsView.swift
//  Zawaj
//
//  Created on 2025-12-22.
//

import SwiftUI

struct QuestionsView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var selectedPartner: User?
    @State private var showingAnswerReveal: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Today's Question")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.white)

                    if let question = viewModel.todayQuestion {
                        Text(question.topic)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.top, 16)

                // Question Card
                if let question = viewModel.todayQuestion {
                    QuestionCard(question: question)
                }

                // Partner Cards - show each partner's status
                if !viewModel.partners.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Partners")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)

                        ForEach(viewModel.partners) { partner in
                            PartnerQuestionStatusCard(
                                partner: partner,
                                userAnswered: viewModel.userAnswered,
                                partnerAnswered: viewModel.partnerAnswers[partner.id] ?? false,
                                onAnswerQuestion: {
                                    // Scroll to answer section
                                },
                                onViewAnswer: {
                                    selectedPartner = partner
                                    showingAnswerReveal = true
                                }
                            )
                        }
                    }
                }

                // Answer Section - based on user's answer status
                if viewModel.userAnswered {
                    // User has answered - show waiting or review state
                    WaitingForPartnersView(
                        partners: viewModel.partners,
                        partnerAnswers: viewModel.partnerAnswers
                    )
                } else {
                    // User hasn't answered - show answer input
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
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 100)
        }
        .sheet(item: $selectedPartner) { partner in
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
        QuestionsView(viewModel: DashboardViewModel())
    }
}
