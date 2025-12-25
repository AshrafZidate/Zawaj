//
//  PartnerDetailView.swift
//  Zawaj
//
//  Created on 2025-12-25.
//

import SwiftUI

struct PartnerDetailView: View {
    let partner: User
    let partnerSinceDate: Date?
    let onSeparate: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showingSeparateAlert = false

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }

    private var birthDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter
    }

    private var age: Int {
        Calendar.current.dateComponents([.year], from: partner.birthday, to: Date()).year ?? 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()

                List {
                    DetailListRow(icon: "at", label: "Username", value: "@\(partner.username)")
                    DetailListRow(icon: "person", label: "Age", value: "\(age) years old")
                    DetailListRow(icon: "calendar", label: "Date of Birth", value: birthDateFormatter.string(from: partner.birthday))
                    DetailListRow(icon: "clock", label: "Marriage Timeline", value: partner.marriageTimeline.isEmpty ? "Not specified" : partner.marriageTimeline)
                    DetailListRow(icon: "text.bubble", label: "Answer Preference", value: partner.answerPreference.isEmpty ? "Not specified" : partner.answerPreference)

                    // Topic Priorities
                    DetailTopicPrioritiesRow(
                        icon: "list.star",
                        label: "Topic Priorities",
                        priorities: partner.topicPriorities
                    )

                    // Partners Since
                    if let sinceDate = partnerSinceDate {
                        DetailListRow(icon: "heart.fill", label: "Partners Since", value: dateFormatter.string(from: sinceDate))
                    }

                    // Separate Button
                    Section {
                        GlassButtonDestructive(title: "Separate") {
                            showingSeparateAlert = true
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(partner.fullName)
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 2) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                    .foregroundColor(.white)
                }
            }
            .alert("Separate from Partner", isPresented: $showingSeparateAlert) {
                Button("Separate", role: .destructive) {
                    onSeparate()
                    dismiss()
                }
            } message: {
                Text("Are you sure you'd like to separate from \(partner.fullName)? This action cannot be undone.")
            }
        }
    }
}

// MARK: - Detail List Row

private struct DetailListRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))

                Text(value.isEmpty ? "—" : value)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }

            Spacer()
        }
        .listRowBackground(Color.white.opacity(0.1))
        .listRowSeparatorTint(.white.opacity(0.2))
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
    }
}

// MARK: - Detail Topic Priorities Row

private struct DetailTopicPrioritiesRow: View {
    let icon: String
    let label: String
    let priorities: [String]

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 20, alignment: .top)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))

                if priorities.isEmpty {
                    Text("Not specified")
                        .font(.subheadline)
                        .foregroundColor(.white)
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(priorities.enumerated()), id: \.offset) { index, topic in
                            HStack(alignment: .top, spacing: 4) {
                                Text("\(index + 1).")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .frame(width: 18, alignment: .leading)
                                Text(topic)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            }

            Spacer()
        }
        .listRowBackground(Color.white.opacity(0.1))
        .listRowSeparatorTint(.white.opacity(0.2))
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
    }
}

#Preview {
    PartnerDetailView(
        partner: User(
            id: "1",
            email: "partner@example.com",
            fullName: "Sarah Johnson",
            username: "sarahj",
            birthday: Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date(),
            marriageTimeline: "1-2 years",
            topicPriorities: ["Faith", "Family", "Career"],
            answerPreference: "Text"
        ),
        partnerSinceDate: Calendar.current.date(byAdding: .month, value: -3, to: Date()),
        onSeparate: {}
    )
}
