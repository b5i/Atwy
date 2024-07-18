//
//  ElementsInfiniteScrollView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 04.01.2024.
//

import SwiftUI
import YouTubeKit
import InfiniteScrollViews

struct ElementsInfiniteScrollView: View {
    @Binding var items: [YTElementWithData]
    @Binding var shouldReloadScrollView: Bool
        
    var fetchNewResultsAtKLast: Int = 5
    var shouldAddBottomSpacing = false
    @ObservedObject private var PSM = PreferencesStorageModel.shared
    @ObservedObject private var NRM = NetworkReachabilityModel.shared
    
    var refreshAction: ((@escaping () -> Void) -> Void)?
    var fetchMoreResultsAction: (() -> Void)?
    
    var topSpacing: CGFloat = 0
    var bottomSpacing: CGFloat = 0
    
    var orientation: Axis = .vertical
    var body: some View {
        if PSM.performanceModeEnabled {
            DefaultElementsInfiniteScrollView(
                items: $items,
                shouldReloadScrollView: $shouldReloadScrollView,
                fetchNewResultsAtKLast: fetchNewResultsAtKLast,
                shouldAddBottomSpacing: shouldAddBottomSpacing,
                refreshAction: refreshAction,
                fetchMoreResultsAction: fetchMoreResultsAction,
                topSpacing: topSpacing,
                bottomSpacing: bottomSpacing,
                orientation: orientation
            )
        } else {
            CustomElementsInfiniteScrollView(
                items: $items,
                shouldReloadScrollView: $shouldReloadScrollView,
                fetchNewResultsAtKLast: fetchNewResultsAtKLast,
                refreshAction: refreshAction,
                fetchMoreResultsAction: fetchMoreResultsAction,
                topSpacing: topSpacing,
                bottomSpacing: bottomSpacing,
                orientation: orientation
            )
        }
    }
}
