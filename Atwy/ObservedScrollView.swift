//
//  ObservedScrollView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 30.09.2023.
//

import SwiftUI

//Inspired from https://saeedrz.medium.com/detect-scroll-position-in-swiftui-3d6e0d81fc6b#:~:text=To%20detect%20the%20scroll%20position,to%20a%20given%20coordinate%20system.
struct ObservedScrollView: ViewModifier {
    
    @State private var scrollPosition: ((CGPoint) -> Void)
    @State private var displayIndicator: Bool
    
    init(displayIndicator: Bool = false, scrollPosition: @escaping ((CGPoint) -> Void)) {
        self.scrollPosition = scrollPosition
        self.displayIndicator = displayIndicator
    }
    
    func body(content: Content) -> some View {
        ScrollView {
            VStack {
                content
            }
            .background(GeometryReader { geometry in
                Color.clear
                    .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).origin)
            })
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                self.scrollPosition(value)
            }
        }
        .coordinateSpace(name: "scroll")
        .scrollIndicators(displayIndicator ? .automatic : .hidden)
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero

    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
    }
}

extension View {
    func observeScrollPosition(displayIndicator: Bool = true, scrollChanged: @escaping (CGPoint) -> Void) -> some View {
        modifier(ObservedScrollView(displayIndicator: displayIndicator, scrollPosition: scrollChanged))
    }
}
