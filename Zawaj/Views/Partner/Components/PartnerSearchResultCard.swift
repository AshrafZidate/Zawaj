//
//  PartnerSearchResultCard.swift
//  Zawaj
//
//  Created on 2025-12-22.
//

import SwiftUI

struct PartnerSearchResultCard: View {
    let user: User
    let isRequestSent: Bool
    let onSendRequest: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                // Initials Badge
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(String(user.fullName.prefix(2).uppercased()))
                            .font(.title3.weight(.bold))
                            .foregroundColor(.white)
                    )

                // User Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.fullName)
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("@\(user.username)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))

                    if !user.gender.isEmpty {
                        if let age = calculateAge(from: user.birthday) {
                            Text("\(user.gender), \(age) years old")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        } else {
                            Text(user.gender)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }

                Spacer()
            }

            // Relationship Info
            if !user.relationshipStatus.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "heart")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))

                    Text(user.relationshipStatus)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            // Send Request Button
            if isRequestSent {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)

                    Text("Request Sent")
                        .font(.body.weight(.medium))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            } else {
                Button(action: onSendRequest) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 16, weight: .medium))

                        Text("Send Partner Request")
                            .font(.body.weight(.medium))
                    }
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
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private func calculateAge(from birthday: Date) -> Int? {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthday, to: Date())
        return ageComponents.year
    }
}

#Preview {
    ZStack {
        GradientBackground()

        PartnerSearchResultCard(
            user: User(
                id: "123",
                email: "sarah@example.com",
                phoneNumber: "",
                isEmailVerified: true,
                isPhoneVerified: false,
                fullName: "Sarah Johnson",
                username: "sarah",
                gender: "Female",
                birthday: Calendar.current.date(byAdding: .year, value: -28, to: Date()) ?? Date(),
                relationshipStatus: "Considering Marriage",
                marriageTimeline: "Within 1 year",
                topicPriorities: [],
                partnerId: nil,
                partnerConnectionStatus: .none,
                answerPreference: "Multiple Choice",
                createdAt: Date(),
                updatedAt: Date(),
                photoURL: nil
            ),
            isRequestSent: false,
            onSendRequest: {}
        )
        .padding(.horizontal, 24)
    }
}
