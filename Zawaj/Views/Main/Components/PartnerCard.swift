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
            HStack {
                // Partner Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(partner.fullName)
                        .font(.body.weight(.medium))
                        .foregroundColor(.white)

                    Text("@\(partner.username)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                // Status indicator
                HStack(spacing: 6) {
                    Image(systemName: status.icon)
                        .font(.caption)
                        .foregroundColor(status.iconColor)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .glassEffect(.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ZStack {
        GradientBackground()

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
