//
//  TodayQuestionCard.swift
//  Zawaj
//
//  Created on 2025-12-21.
//

import SwiftUI

struct TodayQuestionCard: View {
    let question: DailyQuestion?
    let userAnswered: Bool
    let partnerAnswered: Bool
    let partnerName: String?
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📝 Today's Question")
                .font(.headline)
                .foregroundColor(.white)

            if let question = question {
                Text(question.questionText)
                    .font(.title3.weight(.medium))
                    .foregroundColor(.white)
                    .lineLimit(3)

                // Status indicators
                HStack(spacing: 12) {
                    if userAnswered {
                        StatusBadge(text: "✓ You answered", color: .green)
                    }
                    if let partnerName = partnerName {
                        if partnerAnswered {
                            StatusBadge(text: "✓ \(partnerName) answered", color: .green)
                        } else {
                            StatusBadge(text: "⏳ Waiting for \(partnerName)", color: .orange)
                        }
                    }
                }

                GlassmorphicButton(title: userAnswered ? "View Answer" : "Answer Question") {
                    onTap()
                }
            } else {
                Text("Loading today's question...")
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    ZStack {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.18, green: 0.05, blue: 0.35),
                Color(red: 0.72, green: 0.28, blue: 0.44)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )

        TodayQuestionCard(
            question: DailyQuestion(
                id: "1",
                questionText: "What makes you feel most loved in your relationship?",
                questionType: .openEnded,
                options: nil,
                topic: "Love Languages",
                date: Date(),
                createdAt: Date()
            ),
            userAnswered: false,
            partnerAnswered: true,
            partnerName: "Alex",
            onTap: {}
        )
        .padding(.horizontal, 24)
    }
}
