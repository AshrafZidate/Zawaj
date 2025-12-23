//
//  AnswerRevealView.swift
//  Zawaj
//
//  Created on 2025-12-22.
//

import SwiftUI

struct AnswerRevealView: View {
    @Environment(\.dismiss) var dismiss
    let question: DailyQuestion
    let partner: User
    let userAnswer: String
    let partnerAnswer: String

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
                    }
                    .padding(.top, 8)

                    // Question
                    VStack(spacing: 12) {
                        Text(question.topic)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))

                        Text(question.questionText)
                            .font(.title2.weight(.bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }

                    // Your Answer
                    AnswerCard(
                        title: "Your Answer",
                        answer: userAnswer,
                        icon: "person.circle.fill",
                        color: Color(red: 0.94, green: 0.26, blue: 0.42)
                    )

                    // Partner's Answer
                    AnswerCard(
                        title: "\(partner.fullName.split(separator: " ").first.map(String.init) ?? "Partner")'s Answer",
                        answer: partnerAnswer,
                        icon: "person.circle",
                        color: Color.blue
                    )

                    // Comparison or Discussion Prompt
                    ComparisonSection(
                        userAnswer: userAnswer,
                        partnerAnswer: partnerAnswer,
                        questionType: question.questionType
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Answer Card

struct AnswerCard: View {
    let title: String
    let answer: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)

                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
            }

            Text(answer)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Comparison Section

struct ComparisonSection: View {
    let userAnswer: String
    let partnerAnswer: String
    let questionType: QuestionType

    private var answersMatch: Bool {
        userAnswer.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ==
        partnerAnswer.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(spacing: 16) {
            if questionType == .multipleChoice {
                // For multiple choice, show match/difference
                HStack(spacing: 12) {
                    Image(systemName: answersMatch ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundColor(answersMatch ? .green : .orange)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(answersMatch ? "You both chose the same!" : "Different choices")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text(answersMatch ?
                             "Great minds think alike!" :
                             "This is a good conversation starter"
                        )
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()
                }
                .padding(16)
                .background(
                    (answersMatch ? Color.green : Color.orange).opacity(0.15),
                    in: RoundedRectangle(cornerRadius: 12)
                )
            }

            // Discussion Prompt
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.title3)
                        .foregroundColor(.purple)

                    Text("Discussion Starter")
                        .font(.headline)
                        .foregroundColor(.white)
                }

                Text(getDiscussionPrompt())
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func getDiscussionPrompt() -> String {
        if answersMatch {
            return "You both share similar views! Take time to discuss why this matters to you and explore the deeper reasons behind your shared perspective."
        } else {
            return "Different perspectives can lead to growth. Use this as an opportunity to understand each other better and find common ground."
        }
    }
}

#Preview {
    AnswerRevealView(
        question: DailyQuestion(
            id: "1",
            questionText: "What role do you think religion should play in your marriage?",
            questionType: .openEnded,
            options: nil,
            topic: "Religious values",
            date: Date(),
            createdAt: Date()
        ),
        partner: User(
            id: "1",
            email: "partner@example.com",
            fullName: "Sarah Smith"
        ),
        userAnswer: "I believe religion should be a central guiding force in our marriage, helping us make decisions together and raise our children with strong values.",
        partnerAnswer: "Faith is important to me and I want it to be the foundation of our relationship. I'd like us to pray together and attend services regularly."
    )
}
