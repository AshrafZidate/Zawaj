//
//  SignUpTopicPrioritiesView.swift
//  Zawaj
//
//  Created by Ashraf Zidate on 19/12/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct TopicItem: Identifiable, Codable, Transferable {
    let id: UUID
    let title: String

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .topicItem)
    }
}

extension UTType {
    static let topicItem = UTType(exportedAs: "com.zawaj.topicitem")
}

struct SignUpTopicPrioritiesView: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator
    @State private var topics: [TopicItem] = [
        TopicItem(id: UUID(), title: "Religious values"),
        TopicItem(id: UUID(), title: "Family expectations"),
        TopicItem(id: UUID(), title: "Personality and emotional compatibility"),
        TopicItem(id: UUID(), title: "Lifestyle and goals"),
        TopicItem(id: UUID(), title: "Finances and career plans"),
        TopicItem(id: UUID(), title: "Views on marriage roles"),
        TopicItem(id: UUID(), title: "Parenting views"),
        TopicItem(id: UUID(), title: "Conflict resolution style")
    ]

    @State private var dragging: TopicItem?

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: 0) {
                // Back button and progress bar - just below dynamic island
                HStack {
                    Button(action: {
                        coordinator.previousStep()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    ProgressBar(progress: coordinator.currentStep.progress)
                }
                .frame(height: 44)
                .padding(.horizontal, 24)
                .padding(.top, 8)

                // Content section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Order these topics by importance to you")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.white)

                    Text("Top = most important")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                // Reorderable topics list
                List {
                    ForEach(topics) { topic in
                        Text(topic.title)
                            .font(.body.weight(.semibold))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Material.ultraThin, in: RoundedRectangle(cornerRadius: 30))
                            .listRowInsets(EdgeInsets(top: 4, leading: 24, bottom: 4, trailing: 24))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                    .onMove { source, destination in
                        topics.move(fromOffsets: source, toOffset: destination)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .environment(\.editMode, .constant(.active))

                // Continue button
                Button(action: {
                    coordinator.topicPriorities = topics.map { $0.title }
                    coordinator.nextStep()
                }) {
                    Text("Continue")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue, in: RoundedRectangle(cornerRadius: 25))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}

#Preview {
    SignUpTopicPrioritiesView()
        .environmentObject(OnboardingCoordinator())
}
