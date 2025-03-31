//
//  DownloadButtonView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 28.09.2023.
//  Copyright © 2023-2025 Antoine Bollengier. All rights reserved.
//

import SwiftUI
import YouTubeKit

struct DownloadButtonView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var downloader: HLSDownloader? = nil
    @State private var observer: (any NSObjectProtocol)? = nil
    let video: YTVideo
    var videoThumbnailData: Data? = nil
    let downloadURL: URL?
    var body: some View {
        VStack {
            if downloadURL != nil {
               Image(systemName: "arrow.down.circle.fill")
                   .frame(width: 20, height: 20)
            } else if let downloader = downloader {
                StateWithDownloaderView(
                    downloader: downloader,
                    successView: {
                        Image(systemName: "arrow.down.circle.fill")
                            .frame(width: 20, height: 20)
                    },
                    waitingView: {
                        ProgressView()
                            .frame(width: 25, height: 25)
                            .padding()
                    },
                    downloadingOrPausedView: {
                        DownloadStateView(downloader: downloader)
                    },
                    failedOrInactiveView: {
                        DownloadVideoButtonView(video: video, videoThumbnailData: videoThumbnailData, downloader: $downloader)
                    }
                )
            } else {
                DownloadVideoButtonView(video: video, videoThumbnailData: videoThumbnailData, downloader: $downloader)
            }
        }
        .frame(width: 25, height: 25)
        .onAppear {
            if let downloader = DownloadersModel.shared.downloaders[video.videoId] {
                self.downloader = downloader
            }
        }
        .onReceive(of: .atwyDownloadingChanged(for: video.videoId), handler: { _ in
            self.downloader = DownloadersModel.shared.downloaders[video.videoId]
        })
    }
    
    struct StateWithDownloaderView<Success: View, Waiting: View, Downloading: View, Failed: View>: View {
        @ObservedObject var downloader: HLSDownloader
        
        @ViewBuilder var successView: () -> Success
        @ViewBuilder var waitingView: () -> Waiting
        @ViewBuilder var downloadingOrPausedView: () -> Downloading
        @ViewBuilder var failedOrInactiveView: () -> Failed
        var body: some View {
            switch downloader.downloaderState {
            case .success:
                successView()
            case .waiting:
                waitingView()
            case .downloading, .paused:
                downloadingOrPausedView()
            case .failed, .inactive:
                failedOrInactiveView()
            }
        }
    }
}
