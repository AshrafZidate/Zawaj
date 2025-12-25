//
//  SignUpTopicPrioritiesView.swift
//  Zawaj
//
//  Created by Ashraf Zidate on 19/12/2025.
//

import SwiftUI

struct SignUpTopicPrioritiesView: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator
    @State private var topics: [String] = [
        "Religious values",
        "Family expectations",
        "Personality and emotional compatibility",
        "Lifestyle and goals",
        "Finances and career plans",
        "Views on marriage roles",
        "Parenting views",
        "Conflict resolution style"
    ]

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
                Text("Rearrange these topics by importance to you")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 24)

                // Topics list
                List {
                    ForEach(Array(topics.enumerated()), id: \.element) { index, topic in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.body.weight(.semibold))
                                .foregroundColor(.white.opacity(0.6))
                            Text(topic)
                                .font(.body)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    }
                    .onMove { from, to in
                        topics.move(fromOffsets: from, toOffset: to)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .environment(\.editMode, .constant(.active))
                .tint(.clear)
                .padding(.horizontal, 24)

                // Continue button
                GlassButtonPrimary(title: "Continue") {
                    coordinator.topicPriorities = topics
                    coordinator.nextStep()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .swipeBack { coordinator.previousStep() }
    }
}

#Preview {
    SignUpTopicPrioritiesView()
        .environmentObject(OnboardingCoordinator())
}
