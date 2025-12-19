//
//  SignUpAddPartnerView.swift
//  Zawaj
//
//  Created by Ashraf Zidate on 19/12/2025.
//

import SwiftUI

struct SignUpAddPartnerView: View {
    @State private var partnerUsername: String = ""

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
                    Text("Add your partner")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.white)

                    Text("Add your partner so you can begin your Zawāj journey together.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))

                    // Partner username text field
                    TextField("", text: $partnerUsername, prompt: Text("Partner's username").foregroundColor(.secondary))
                        .font(.body)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 16)
                        .frame(height: 50)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .textContentType(.username)
                        .autocapitalization(.none)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()

                // Action buttons
                VStack(spacing: 24) {
                    GlassmorphicButton(title: "Send partner request") {
                        // Send partner request
                    }

                    GlassmorphicButton(title: "Invite partner to Zawāj") {
                        // Invite partner via share sheet
                    }

                    GlassmorphicButton(title: "I don't have a partner") {
                        // Skip partner connection
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}

#Preview {
    SignUpAddPartnerView()
}
