//
//  PartnerCard.swift
//  Zawaj
//
//  Created on 2025-12-22.
//

import SwiftUI

enum PartnerAnswerStatus {
    case answerBoth              // Neither user nor partner answered
    case answerToUnlock          // User hasn't answered, partner may or may not have
    case waitingForPartner       // User answered, partner hasn't
    case reviewAnswers           // Both answered
    case newQuestionsTomorrow    // All questions answered for today

    var message: String {
        switch self {
        case .answerBoth:
            return "Answer today's questions (both)"
        case .answerToUnlock:
            return "Answer today's questions to unlock theirs"
        case .waitingForPartner:
            return "Waiting for their answers"
        case .reviewAnswers:
            return "Review their answers"
        case .newQuestionsTomorrow:
            return "New questions tomorrow"
        }
    }

    var icon: String {
        switch self {
        case .answerBoth:
            return "bubble.left.and.bubble.right"
        case .answerToUnlock:
            return "lock.fill"
        case .waitingForPartner:
            return "clock.fill"
        case .reviewAnswers:
            return "checkmark.circle.fill"
        case .newQuestionsTomorrow:
            return "moon.stars.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .answerBoth:
            return Color(red: 0.94, green: 0.26, blue: 0.42)
        case .answerToUnlock:
            return Color.orange
        case .waitingForPartner:
            return Color.blue
        case .reviewAnswers:
            return Color.green
        case .newQuestionsTomorrow:
            return Color.purple
        }
    }

    static func determine(userAnswered: Bool, partnerAnswered: Bool) -> PartnerAnswerStatus {
        if userAnswered && partnerAnswered {
            return .reviewAnswers
        } else if userAnswered && !partnerAnswered {
            return .waitingForPartner
        } else if !userAnswered && partnerAnswered {
            return .answerToUnlock
        } else {
            return .answerBoth
        }
    }
}

struct PartnerCard: View {
    let partner: User
    let userAnswered: Bool
    let partnerAnswered: Bool
    let onTap: () -> Void

    private var status: PartnerAnswerStatus {
        PartnerAnswerStatus.determine(userAnswered: userAnswered, partnerAnswered: partnerAnswered)
    }

    private var initials: String {
        let components = partner.fullName.split(separator: " ")
        if components.count >= 2 {
            return "\(components[0].prefix(1))\(components[1].prefix(1))".uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "?"
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Partner Avatar/Initials
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.94, green: 0.26, blue: 0.42).opacity(0.6),
                                Color(red: 0.82, green: 0.16, blue: 0.32).opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(initials)
                            .font(.title3.weight(.bold))
                            .foregroundColor(.white)
                    )

                // Partner Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(partner.fullName)
                        .font(.headline)
                        .foregroundColor(.white)

                    // Status Row
                    HStack(spacing: 6) {
                        Image(systemName: status.icon)
                            .font(.caption)
                            .foregroundColor(status.iconColor)

                        Text(status.message)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    // Relationship Status
                    Text(partner.relationshipStatus)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(PlainButtonStyle())
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

        VStack(spacing: 16) {
            PartnerCard(
                partner: User(
                    id: "1",
                    email: "alex@example.com",
                    fullName: "Alex Johnson",
                    relationshipStatus: "Engaged"
                ),
                userAnswered: false,
                partnerAnswered: false,
                onTap: {}
            )

            PartnerCard(
                partner: User(
                    id: "2",
                    email: "sarah@example.com",
                    fullName: "Sarah Smith",
                    relationshipStatus: "Married"
                ),
                userAnswered: false,
                partnerAnswered: true,
                onTap: {}
            )

            PartnerCard(
                partner: User(
                    id: "3",
                    email: "mike@example.com",
                    fullName: "Mike Davis",
                    relationshipStatus: "Talking Stage"
                ),
                userAnswered: true,
                partnerAnswered: false,
                onTap: {}
            )

            PartnerCard(
                partner: User(
                    id: "4",
                    email: "emma@example.com",
                    fullName: "Emma Wilson",
                    relationshipStatus: "Single"
                ),
                userAnswered: true,
                partnerAnswered: true,
                onTap: {}
            )
        }
        .padding(.horizontal, 24)
    }
}
