//
//  RecommendedVideosView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 08.07.2024.
//  Copyright © 2024-2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI
import YouTubeKit

struct RecommendedVideosView: View {
    @ObservedObject var playerItem: YTAVPlayerItem
    
    var topSpacing: CGFloat = 0
    var bottomSpacing: CGFloat = 0
    
    @ObservedObject private var NRM = NetworkReachabilityModel.shared
    var body: some View {
        VStack {
            if let trendingVideos = self.playerItem.moreVideoInfos?.recommendedVideos
                .filter({ trendingVideo in
                    if NRM.connected {
                        return true
                    }
                    return PersistenceModel.shared.currentData.downloadedVideoIds.contains(where: {$0.videoId == (trendingVideo as? YTVideo)?.videoId})
                }) {
                let elementsBinding = Binding<[YTElementWithData]>(get: {
                    return trendingVideos.map({YTElementWithData(element: $0, data: .init(allowChannelLinking: false, videoViewMode: .halfThumbnail))})
                }, set: {_ in})
                ElementsInfiniteScrollView(items: elementsBinding, shouldReloadScrollView: .constant(false), fetchMoreResultsAction: {
                    self.playerItem.fetchMoreRecommendedVideos()
                }, topSpacing: topSpacing, bottomSpacing: bottomSpacing, orientation: .vertical)
            } else if self.playerItem.isFetchingMoreRecommendedVideos || self.playerItem.isFetchingMoreVideoInfos {
                LoadingView(style: .light)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Color.clear.frame(width: 0, height: 0)
            }
        }
    }
}
