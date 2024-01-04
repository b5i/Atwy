//
//  ElementsInfiniteScrollView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 04.01.2024.
//

import SwiftUI
import YouTubeKit

struct ElementsInfiniteScrollView: View {
    @Binding var items: [any YTSearchResult]
    @Binding var shouldReloadScrollView: Bool
    @State var fetchNewResultsAtKLast: Int = 5
    @ObservedObject private var PSM = PreferencesStorageModel.shared
    @ObservedObject private var NRM = NetworkReachabilityModel.shared
    
    var refreshAction: ((@escaping () -> Void) -> Void)?
    var fetchMoreResultsAction: (() -> Void)?
    var body: some View {
        let performanceMode = PSM.propetriesState[.performanceMode] as? PreferencesStorageModel.Properties.PerformanceModes
        if performanceMode == .limited {
            CustomElementsInfiniteScrollView(
                items: $items, 
                shouldReloadScrollView: $shouldReloadScrollView,
                fetchNewResultsAtKLast: fetchNewResultsAtKLast,
                refreshAction: refreshAction,
                fetchMoreResultsAction: fetchMoreResultsAction
            )
        } else {
            DefaultElementsInfiniteScrollView(
                items: $items,
                shouldReloadScrollView: $shouldReloadScrollView,
                fetchNewResultsAtKLast: fetchNewResultsAtKLast,
                refreshAction: refreshAction,
                fetchMoreResultsAction: fetchMoreResultsAction
            )
        }
    }
}
