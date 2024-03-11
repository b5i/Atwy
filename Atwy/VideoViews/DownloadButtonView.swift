//
//  DownloadButtonView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 28.09.2023.
//

import SwiftUI
import YouTubeKit

struct DownloadButtonView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var downloader: HLSDownloader? = nil
    @State private var observer: (any NSObjectProtocol)? = nil
    var isShort: Bool = false
    let video: YTVideo
    var videoThumbnailData: Data? = nil
    var downloadURL: URL?
    @ObservedObject private var DCMM = DownloadCoordinatorManagerModel.shared
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
                        DownloadVideoButtonView(video: video, isShort: isShort, videoThumbnailData: videoThumbnailData, downloader: $downloader)
                    }
                )
            } else {
                DownloadVideoButtonView(video: video, isShort: isShort, videoThumbnailData: videoThumbnailData, downloader: $downloader)
            }
        }
        .frame(width: 25, height: 25)
        .onAppear {
            if let downloader = downloads.first(where: {$0.video?.videoId == video.videoId}) {
                self.downloader = downloader
            } else {
                self.observer = NotificationCenter.default.addObserver(forName: .atwyDownloadingChanged(for: video.videoId), object: nil, queue: nil, using: { _ in
                    self.downloader = downloads.first(where: {$0.video?.videoId == video.videoId})
                })
            }
        }
        .onDisappear {
            if let observer = self.observer {
                NotificationCenter.default.removeObserver(observer)
            }
        }
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
