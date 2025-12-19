//
//  ProgressBar.swift
//  Zawaj
//
//  Created by Ashraf Zidate on 19/12/2025.
//

import SwiftUI

struct ProgressBar: View {
    let progress: Double // 0.0 to 1.0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(white: 0.47, opacity: 0.2))
                    .frame(height: 6)

                // Filled portion
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(red: 0.0, green: 0.53, blue: 1.0)) // #08f
                    .frame(width: max(6, geometry.size.width * progress), height: 6)
            }
        }
        .frame(height: 6)
        .padding(.horizontal, 16)
    }
}

#Preview {
    VStack(spacing: 20) {
        ProgressBar(progress: 0.0)
        ProgressBar(progress: 0.1)
        ProgressBar(progress: 0.5)
        ProgressBar(progress: 1.0)
    }
    .padding()
    .background(Color.purple)
}
