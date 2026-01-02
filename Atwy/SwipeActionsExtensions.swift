//
//  SwipeActionsExtensions.swift
//  Atwy
//
//  Created by Antoine Bollengier on 08.10.2023.
//  Copyright © 2023-2026 Antoine Bollengier. All rights reserved.
//

import Foundation
import SwiftUI
import SwipeActions

struct SwipeActionViewModifier<LeadingActions, TrailingActions>: ViewModifier where LeadingActions: View, TrailingActions: View {
    @ViewBuilder var leadingActions: (SwipeContext) -> LeadingActions
    @ViewBuilder var trailingActions: (SwipeContext) -> TrailingActions
    var minimumSwipeDistance: CGFloat = 2
    func body(content: Content) -> some View {
        SwipeView(label: {
            content
        }, leadingActions: { context in
            leadingActions(context)
        }, trailingActions: { context in
            trailingActions(context)
        })
        .swipeMinimumDistance(minimumSwipeDistance)
    }
}

extension View {
    func swipeAction<LeadingActions, TrailingActions>(@ViewBuilder leadingActions: @escaping (SwipeContext) -> LeadingActions, @ViewBuilder trailingActions: @escaping (SwipeContext) -> TrailingActions, minimumSwipeDistance: CGFloat = 2) -> some View where LeadingActions: View, TrailingActions: View {
        modifier(SwipeActionViewModifier(leadingActions: leadingActions, trailingActions: trailingActions, minimumSwipeDistance: minimumSwipeDistance))
    }
}
