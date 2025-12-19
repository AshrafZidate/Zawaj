//
//  SignUpUsernameView.swift
//  Zawaj
//
//  Created by Ashraf Zidate on 19/12/2025.
//

import SwiftUI

struct SignUpUsernameView: View {
    @State private var username: String = ""

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
                    Text("Username")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.white)

                    Text("Choose your username")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))

                    // Username text field
                    TextField("", text: $username, prompt: Text("Username").foregroundColor(.secondary))
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

                // Continue button - just above bottom
                GlassmorphicButton(title: "Continue") {
                    // Continue action
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}

#Preview {
    SignUpUsernameView()
}
