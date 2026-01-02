//
//  CustomElementsInfiniteScrollView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 12.10.2023.
//  Copyright © 2023-2026 Antoine Bollengier. All rights reserved.
//

import Foundation
import InfiniteScrollViews
import SwiftUI
import SwipeActions
import YouTubeKit

struct CustomElementsInfiniteScrollView: View {
    @Binding var items: [YTElementWithData]
    @Binding var shouldReloadScrollView: Bool
    var fetchNewResultsAtKLast: Int = 5
    @ObservedObject private var PSM = PreferencesStorageModel.shared
    @ObservedObject private var NRM = NetworkReachabilityModel.shared
    
    var refreshAction: ((@escaping () -> Void) -> Void)?
    var fetchMoreResultsAction: (() -> Void)?
    
    // not really useful in this view for the moment
    //var topSpacing: CGFloat = 0
    //var bottomSpacing: CGFloat = 0
    
    var orientation: Axis = .vertical
    var body: some View {
        GeometryReader { geometry in
            InfiniteScrollView(
                frame: .init(x: 0, y: 0, width: geometry.size.width, height: (PSM.videoViewMode == .halfThumbnail) ? 205 : geometry.size.height),
                changeIndex: 0 as Int,
                content: { resultIndex in
                    HStack(spacing: 0) {
                        if self.items.count > resultIndex {
                            let item = self.items[resultIndex]
                            switch item.element {
                            case let item as YTChannel:
                                item.getView()
                                .frame(width: geometry.size.width, height: 180, alignment: .center)
                            case let item as YTPlaylist:
                                SwipeView {
                                    item.getView()
                                    .padding(.horizontal, 5)
                                } trailingActions: { context in
                                    if NRM.connected {
                                        if let channel = item.channel {
                                            SwipeAction(
                                                action: {},
                                                label: { _ in
                                                    Image(systemName: "person.crop.rectangle")
                                                        .foregroundStyle(.white)
                                                },
                                                background: { _ in
                                                    Rectangle()
                                                        .fill(.cyan)
                                                        .routeTo(.channelDetails(channel: channel))
                                                        .onDisappear {
                                                            context.state.wrappedValue = .closed
                                                        }
                                                }
                                            )
                                        }
                                    }
                                }
                                .swipeMinimumDistance(50)
                                .frame(width: geometry.size.width, height: 180, alignment: .center)
                            case let rawVideo as YTVideo:
                                VideoInScrollView(video: rawVideo.withData(item.data), size: geometry.size)
                            default:
                                Color.clear.frame(width: 0, height: 0)
                            }
                        } else {
                            Color.clear.frame(width: 0, height: 0)
                        }
                    }
                    //                    .border(.white)
                },
                contentFrame: { resultIndex in
                    if self.items.count > resultIndex {
                        let item = self.items[resultIndex]
                        switch item.element {
                        case is YTVideo:
                            if PSM.videoViewMode == .halfThumbnail {
                                return .init(x: 0, y: 0, width: geometry.size.width, height: 205)
                            } else {
                                // Big thumbnail view by default
                                return .init(x: 0, y: 0, width: geometry.size.width, height: geometry.size.width * 9/16 + 90)
                            }
                        case is YTPlaylist:
                            return .init(x: 0, y: 0, width: geometry.size.width, height: 180)
                        case is YTChannel:
                            return .init(x: 0, y: 0, width: geometry.size.width, height: 180)
                        default:
                            return .init(x: 0, y: 0, width: 0, height: 0)
                        }
                    } else {
                        return .init(x: 0, y: 0, width: 0, height: 0)
                    }
                },
                increaseIndexAction: { resultIndex in
                    if resultIndex < items.count - 1 {
                        let takenItemsCount = items.count > fetchNewResultsAtKLast ? fetchNewResultsAtKLast : items.count - 1
                        if resultIndex + takenItemsCount == items.count - 1 {
                            fetchMoreResultsAction?()
                        }
                        return resultIndex + 1
                    } else {
                        return nil
                    }
                },
                decreaseIndexAction: { resultIndex in
                    if resultIndex > 0 {
                        return resultIndex - 1
                    } else {
                        return nil
                    }
                },
                orientation: self.orientation == .horizontal ? .horizontal : .vertical,
                refreshAction: refreshAction,
                contentMultiplier: (PSM.videoViewMode == .halfThumbnail) ? 15 : 6,
                updateBinding: $shouldReloadScrollView
            )
            .id(PSM.videoViewMode == .halfThumbnail)
        }
    }
}
