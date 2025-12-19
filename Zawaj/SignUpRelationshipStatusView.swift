//
//  SignUpRelationshipStatusView.swift
//  Zawaj
//
//  Created by Ashraf Zidate on 19/12/2025.
//

import SwiftUI

struct SignUpRelationshipStatusView: View {
    @State private var selectedStatus: String?

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
                    Text("What is your current relationship status?")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()

                // Relationship status selection buttons
                VStack(spacing: 24) {
                    GlassmorphicButton(title: "Single") {
                        selectedStatus = "Single"
                    }

                    GlassmorphicButton(title: "Talking Stage") {
                        selectedStatus = "Talking Stage"
                    }

                    GlassmorphicButton(title: "Engaged") {
                        selectedStatus = "Engaged"
                    }

                    GlassmorphicButton(title: "Married") {
                        selectedStatus = "Married"
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}

#Preview {
    SignUpRelationshipStatusView()
}
