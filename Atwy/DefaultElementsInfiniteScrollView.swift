//
//  DefaultElementsInfiniteScrollView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 03.01.2024.
//

import SwiftUI
import YouTubeKit
import SwipeActions

struct DefaultElementsInfiniteScrollView: View {
    @Binding var items: [any YTSearchResult]
    @Binding var shouldReloadScrollView: Bool
    @State var fetchNewResultsAtKLast: Int = 5
    @ObservedObject private var PSM = PreferencesStorageModel.shared
    @ObservedObject private var NRM = NetworkReachabilityModel.shared
    
    var refreshAction: ((@escaping () -> Void) -> Void)?
    var fetchMoreResultsAction: (() -> Void)?
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVStack {
                    let itemsCount = items.count
                    if itemsCount < fetchNewResultsAtKLast {
                        Color.clear.frame(width: 0, height: 0)
                            .onAppear {
                                fetchMoreResultsAction?()
                            }
                    }
                    ForEach(Array(items.enumerated()), id: \.offset) { itemOffset, item in
                        HStack(spacing: 0) {
                            if itemsCount >= fetchNewResultsAtKLast && itemsCount - itemOffset == fetchNewResultsAtKLast + 1 {
                                Color.clear.frame(width: 0, height: 0)
                                    .onAppear {
                                        fetchMoreResultsAction?()
                                    }
                            }
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
                        }
                    }
                }
            }
            .refreshable {
                refreshAction?{}
            }
        }
        .id(PSM.propetriesState[.videoViewMode] as? PreferencesStorageModel.Properties.VideoViewModes == .halfThumbnail)
    }
}
