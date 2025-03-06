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
    @Binding var items: [YTElementWithData]
    @Binding var shouldReloadScrollView: Bool
    
    var fetchNewResultsAtKLast: Int = 5
    var shouldAddBottomSpacing: Bool = false // add the height of the navigationbar to the bottom
    @ObservedObject private var PSM = PreferencesStorageModel.shared
    @ObservedObject private var NRM = NetworkReachabilityModel.shared
    
    var refreshAction: ((@escaping () -> Void) -> Void)?
    var fetchMoreResultsAction: (() -> Void)?
    
    var topSpacing: CGFloat = 0
    var bottomSpacing: CGFloat = 0
    
    var orientation: Axis = .vertical
    var body: some View {
        GeometryReader { geometry in
            // We could switch to List very easily but a performance check is needed as we already use a lazyvstack
            // List {
            ScrollView(orientation == .horizontal ? [.horizontal] : [.vertical]) {
                Color.clear.frame(height: topSpacing)
                LazyStack(orientation: orientation, content: {
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
                                VideoInScrollView(video: rawVideo.withData(item.data), geometry: geometry)
                            default:
                                Color.clear.frame(width: 0, height: 0)
                            }
                        }
                    }
                })
            }
            .contentMargins(.bottom, length: bottomSpacing + (shouldAddBottomSpacing ? 49 : 0))
            // .listStyle(.plain)
            .optionalRefreshable(self.refreshAction == nil ? nil : {
                refreshAction?{}
            })
        }
        .id(PSM.videoViewMode == .halfThumbnail)
    }
}
