//
//  HeaderView.swift
//  Zawaj
//
//  Created on 2025-12-21.
//

import SwiftUI

struct HeaderView: View {
    let userName: String?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText())
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                Text(dateText())
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            Button(action: {
                // TODO: Navigate to profile
            }) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }
        }
    }

    private func greetingText() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeOfDay = hour < 12 ? "Good morning" : hour < 18 ? "Good afternoon" : "Good evening"
        if let name = userName {
            return "\(timeOfDay), \(name)"
        }
        return timeOfDay
    }

    private func dateText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
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

        HeaderView(userName: "Sarah")
            .padding(.horizontal, 24)
    }
}
