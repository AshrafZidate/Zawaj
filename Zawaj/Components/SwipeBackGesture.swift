//
//  SwipeBackGesture.swift
//  Zawaj
//
//  Created on 2025-12-25.
//

import SwiftUI

struct SwipeBackGesture: ViewModifier {
    let onSwipeBack: () -> Void

    @State private var offset: CGFloat = 0
    @State private var isDragging = false
    @State private var screenWidth: CGFloat = 0

    private let threshold: CGFloat = 100
    private let edgeWidth: CGFloat = 30

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Only allow swipe from left edge
                            if value.startLocation.x < edgeWidth && value.translation.width > 0 {
                                isDragging = true
                                offset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            if isDragging {
                                if value.translation.width > threshold {
                                    // Trigger back action
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        offset = geometry.size.width
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        onSwipeBack()
                                        offset = 0
                                    }
                                } else {
                                    // Snap back
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        offset = 0
                                    }
                                }
                                isDragging = false
                            }
                        }
                )
        }
    }
}

extension View {
    func swipeBack(action: @escaping () -> Void) -> some View {
        modifier(SwipeBackGesture(onSwipeBack: action))
    }
}
