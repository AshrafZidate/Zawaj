//
//  TodayQuestionCard.swift
//  Zawaj
//
//  Created on 2025-12-21.
//

import SwiftUI

struct TodayQuestionCard: View {
    let topicName: String?
    let subtopicName: String?
    let questionText: String?
    let progressText: String
    let userAnswered: Bool
    let partnerAnswered: Bool
    let partnerName: String?
    let isComplete: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Today's Questions")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                if !progressText.isEmpty && !isComplete {
                    Text(progressText)
                        .font(.caption.weight(.medium))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1), in: Capsule())
                }
            }

            if isComplete {
                // All done state
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("All done for today!")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white)

                        Text("New questions tomorrow")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            } else if let topic = topicName {
                // Topic info
                VStack(alignment: .leading, spacing: 4) {
                    Text(topic)
                        .font(.title3.weight(.medium))
                        .foregroundColor(.white)

                    if let subtopic = subtopicName {
                        Text(subtopic)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                if let question = questionText {
                    Text(question)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                }

                // Status indicators
                HStack(spacing: 12) {
                    if userAnswered {
                        StatusBadge(text: "You answered", color: .green)
                    }
                    if let partnerName = partnerName {
                        if partnerAnswered {
                            StatusBadge(text: "\(partnerName) answered", color: .green)
                        } else {
                            StatusBadge(text: "Waiting for \(partnerName)", color: .orange)
                        }
                    }
                }

                GlassButton(title: userAnswered ? "View Progress" : "Answer Questions") {
                    onTap()
                }
            } else {
                Text("Loading today's questions...")
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

// Legacy initializer for backward compatibility
extension TodayQuestionCard {
    init(
        question: DailyQuestion?,
        userAnswered: Bool,
        partnerAnswered: Bool,
        partnerName: String?,
        onTap: @escaping () -> Void
    ) {
        self.topicName = question?.topic
        self.subtopicName = nil
        self.questionText = question?.questionText
        self.progressText = ""
        self.userAnswered = userAnswered
        self.partnerAnswered = partnerAnswered
        self.partnerName = partnerName
        self.isComplete = false
        self.onTap = onTap
    }
}

#Preview {
    ZStack {
        GradientBackground()

        VStack(spacing: 16) {
            TodayQuestionCard(
                topicName: "Religious Values",
                subtopicName: "Core Relationship With Islam",
                questionText: "What role do you think religion should play in your marriage?",
                progressText: "2 of 4",
                userAnswered: false,
                partnerAnswered: true,
                partnerName: "Alex",
                isComplete: false,
                onTap: {}
            )

            TodayQuestionCard(
                topicName: "Religious Values",
                subtopicName: "Core Relationship With Islam",
                questionText: nil,
                progressText: "4 of 4",
                userAnswered: true,
                partnerAnswered: true,
                partnerName: "Alex",
                isComplete: true,
                onTap: {}
            )
        }
        .padding(.horizontal, 24)
    }
}
