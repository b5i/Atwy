//
//  DownloadStateView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 25.01.23.
//

import SwiftUI
import YouTubeKit

struct DownloadStateView: View {
    @Environment(\.colorScheme) private var colorScheme
    var displayRemainingTime: Bool = false
    let downloaded: Bool
    let video: YTVideo
    let isShort: Bool
    var videoThumbnailData: Data?
    @ObservedObject var downloader: HLSDownloader
    var body: some View {
        if downloaded {
            Image(systemName: "arrow.down.circle.fill")
                .frame(width: 20, height: 20)
        } else {
            if downloader.downloaderState == .inactive || downloader.downloaderState == .failed || downloader.downloaderState == .success {
                let downloaderBinding: Binding<HLSDownloader?> = Binding(get: {
                    return self.downloader
                }, set: { _ in})
                DownloadVideoButtonView(video: video, isShort: isShort, videoThumbnailData: videoThumbnailData, downloader: downloaderBinding)
            } else if downloader.downloaderState == .waiting {
                ProgressView()
                    .frame(width: 25, height: 25)
                    .padding()
            } else if downloader.downloaderState == .downloading && downloader.percentComplete == 0.0 {
                ProgressView()
                    .frame(width: 25, height: 25)
                    .padding()
            } else {
                CircularProgressView(progress: downloader.percentComplete)
                    .frame(width: 20, height: 20)
                    .padding()
            }
        }
    }
}
