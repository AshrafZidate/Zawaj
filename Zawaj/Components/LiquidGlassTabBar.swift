//
//  LiquidGlassTabBar.swift
//  Zawaj
//
//  Created on 2025-12-21.
//

import SwiftUI

struct TabBarItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let tag: Int
}

struct LiquidGlassTabBar: View {
    @Binding var selectedTab: Int
    let items: [TabBarItem]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                TabBarButton(
                    item: item,
                    isSelected: selectedTab == item.tag
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = item.tag
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 49) // Standard iOS tab bar height
        .background(
            // Ultra-thin material matching iOS tab bars
            .ultraThinMaterial
        )
        .overlay(
            // Hairline separator at top
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(height: 0.33),
            alignment: .top
        )
    }
}

struct TabBarButton: View {
    let item: TabBarItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 1) {
                // Icon - 25x25pt is standard iOS tab bar icon size
                Image(systemName: isSelected ? "\(item.icon).fill" : item.icon)
                    .font(.system(size: 25))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isSelected ? Color(red: 0.94, green: 0.26, blue: 0.42) : Color.primary.opacity(0.6))
                    .frame(width: 25, height: 25)
                    .padding(.top, 1)

                // Label - iOS standard tab bar label size
                Text(item.title)
                    .font(.system(size: 10))
                    .foregroundStyle(isSelected ? Color(red: 0.94, green: 0.26, blue: 0.42) : Color.primary.opacity(0.6))
                    .padding(.bottom, 1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
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
        .ignoresSafeArea()

        VStack {
            Spacer()

            LiquidGlassTabBar(
                selectedTab: .constant(0),
                items: [
                    TabBarItem(icon: "house", title: "Home", tag: 0),
                    TabBarItem(icon: "questionmark.bubble", title: "Questions", tag: 1),
                    TabBarItem(icon: "clock.arrow.circlepath", title: "History", tag: 2),
                    TabBarItem(icon: "person", title: "Profile", tag: 3)
                ]
            )
        }
    }
}
