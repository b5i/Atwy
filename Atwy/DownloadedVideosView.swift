//
//  DownloadedVideosView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 27.11.22.
//  Copyright © 2022-2026 Antoine Bollengier. All rights reserved.
//

import SwiftUI
import YouTubeKit

struct DownloadedVideosView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DownloadedVideo.timestamp, ascending: true)],
        animation: .default)
    private var downloadedVideos: FetchedResults<DownloadedVideo>
    @State private var search: String = ""
    @ObservedObject private var VPM = VideoPlayerModel.shared
    @ObservedObject private var PSM = PreferencesStorageModel.shared
    var body: some View {
        GeometryReader { geometry in
            VStack {
                DownloadingsHeaderView()
                ScrollView {
                    //                        List {
                    LazyVStack {
                        let videoViewHeight = PSM.videoViewMode == .halfThumbnail ? 180 : geometry.size.width * 9/16 + 90
                        
                        ForEach(sortedVideos) { (video: DownloadedVideo) in
                            let convertedResult = video.toYTVideo()
                            
                            VideoFromSearchView(videoWithData: convertedResult.withData(.init(channelAvatarData: video.channel?.thumbnail, thumbnailData: video.thumbnail)))
                                .frame(width: geometry.size.width, height: videoViewHeight, alignment: .center)
                        }
                        Color.clear
                            .frame(height: 30)
                    }
                }
                .contentMargins(.bottom, length: VPM.currentItem != nil ? 50 : 0)
            }
#if os(macOS)
            .searchable(text: $search, placement: .toolbar)
#else
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always))
#endif
            .autocorrectionDisabled(true)
            .navigationTitle("Downloads")
            .sortingModeSelectorButton(forPropertyType: .downloadsSortingMode)
            .customNavigationTitleWithRightIcon {
                ShowSettingsButtonView()
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .routeContainer()
    }
    
    var sortedVideos: [DownloadedVideo] {
        return self.downloadedVideos.filter({$0.matchesQuery(search)}).sorted(by: {
            switch self.PSM.downloadsSortingMode {
            case .newest:
                return $0.timestamp > $1.timestamp
            case .oldest:
                return $0.timestamp < $1.timestamp
            case .title:
                return ($0.title ?? "") < ($1.title ?? "")
            case .channelName:
                return ($0.channel?.name ?? "") < ($1.channel?.name ?? "")
            }
        })
    }
}
