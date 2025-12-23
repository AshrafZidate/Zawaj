//
//  LaunchScreen.swift
//  Zawaj
//
//  Created by Ashraf Zidate on 19/12/2025.
//

import SwiftUI

struct LaunchScreen: View {
    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: 0) {
                // Top section with logo
                Spacer()

                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)

                Spacer()

                // Middle section with title
                VStack(spacing: 0) {
                    Text("Zawāj")
                        .font(.custom("Platypi", size: 64))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("الزَّواجُ")
                        .font(.custom("Amiri", size: 40))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)

                Spacer()

                // Bottom section with tagline
                Text("Halal connection. Sacred intention.")
                    .font(.custom("NunitoSans", size: 20))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Spacer()
            }
            .padding(.vertical, 100)
        }
    }
}

#Preview {
    LaunchScreen()
}
