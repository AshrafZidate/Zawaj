//
//  GradientBackground.swift
//  Zawaj
//
//  Created on 2025-12-23.
//

import SwiftUI

struct GradientBackground: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.18, green: 0.05, blue: 0.35),
                Color(red: 0.72, green: 0.28, blue: 0.44)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

#Preview {
    GradientBackground()
}
