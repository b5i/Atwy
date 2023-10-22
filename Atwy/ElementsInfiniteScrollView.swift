//
//  ElementsInfiniteScrollView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 12.10.2023.
//

import Foundation
import InfiniteScrollViews
import SwiftUI
import SwipeActions
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
        GeometryReader { geometry in
            InfiniteScrollView(
                frame: .init(x: 0, y: 0, width: geometry.size.width, height: (PSM.propetriesState[.videoViewMode] as? PreferencesStorageModel.Properties.VideoViewModes == .halfThumbnail) ? 205 : geometry.size.height),
                changeIndex: 0 as Int,
                content: { resultIndex in
                    HStack(spacing: 0) {
                        if self.items.count > resultIndex {
                            let item = self.items[resultIndex]
                            switch item {
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
                                                    NavigationLink(
                                                        destination:
                                                            ChannelDetailsView(channel: channel).onAppear {
                                                                context.state.wrappedValue = .closed
                                                            }
                                                        , label: {
                                                            Rectangle()
                                                                .fill(.cyan)
                                                        }
                                                    )
                                                }
                                            )
                                        }
                                    }
                                }
                                .swipeMinimumDistance(50)
                                .frame(width: geometry.size.width, height: 180, alignment: .center)
                            case let item as YTVideo:
                                if let state = PSM.propetriesState[.videoViewMode] as? PreferencesStorageModel.Properties.VideoViewModes, state == .halfThumbnail {
                                    VideoFromSearchView(video: item)
                                        .frame(width: geometry.size.width, height: 180, alignment: .center)
                                } else {
                                    // Big thumbnail view by default
                                    VideoFromSearchView(video: item)
                                        .frame(width: geometry.size.width, height: geometry.size.width * 9/16 + 90, alignment: .center)
                                    //                                            .padding(.bottom, resultIndex == 0 ? geometry.size.height * 0.2 : 0)
                                }
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
                        switch item {
                        case is YTVideo:
                            if let state = PSM.propetriesState[.videoViewMode] as? PreferencesStorageModel.Properties.VideoViewModes, state == .halfThumbnail {
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
                orientation: .vertical,
                refreshAction: refreshAction,
                contentMultiplier: (PSM.propetriesState[.videoViewMode] as? PreferencesStorageModel.Properties.VideoViewModes == .halfThumbnail) ? 15 : 6,
                updateBinding: $shouldReloadScrollView
            )
            .id(PSM.propetriesState[.videoViewMode] as? PreferencesStorageModel.Properties.VideoViewModes == .halfThumbnail)
        }
    }
}
