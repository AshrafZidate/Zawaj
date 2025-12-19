//
//  SignUpMarriageTimelineView.swift
//  Zawaj
//
//  Created by Ashraf Zidate on 19/12/2025.
//

import SwiftUI

struct SignUpMarriageTimelineView: View {
    @State private var selectedTimeline: String?

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.18, green: 0.05, blue: 0.35), // #2e0d5a
                    Color(red: 0.72, green: 0.28, blue: 0.44)  // #b7486f
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Back button and progress bar - just below dynamic island
                HStack {
                    Button(action: {
                        // Back action
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    ProgressBar(progress: 0.1)
                }
                .frame(height: 44)
                .padding(.horizontal, 24)
                .padding(.top, 8)

                // Content section
                VStack(alignment: .leading, spacing: 16) {
                    Text("How soon are you hoping to become married?")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()

                // Timeline selection buttons
                VStack(spacing: 24) {
                    GlassmorphicButton(title: "1-3 Months") {
                        selectedTimeline = "1-3 Months"
                    }

                    GlassmorphicButton(title: "3-6 Months") {
                        selectedTimeline = "3-6 Months"
                    }

                    GlassmorphicButton(title: "6-12 Months") {
                        selectedTimeline = "6-12 Months"
                    }

                    GlassmorphicButton(title: "1-2 Years") {
                        selectedTimeline = "1-2 Years"
                    }

                    GlassmorphicButton(title: "Not sure") {
                        selectedTimeline = "Not sure"
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}

#Preview {
    SignUpMarriageTimelineView()
}
