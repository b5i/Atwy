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
    @State var displayRemainingTime: Bool = false
    @State var downloaded: Bool
    @State var video: YTVideo
    @State var isShort: Bool
    @State var videoThumbnailData: Data?
    @ObservedObject var downloader: HLSDownloader
    var body: some View {
        if downloaded {
            Image(systemName: "arrow.down.circle.fill")
                .frame(width: 20, height: 20)
        } else {
            if downloader.downloaderState == .inactive || downloader.downloaderState == .failed {
                DownloadVideoButtonView(video: video, isShort: isShort, videoThumbnailData: videoThumbnailData, downloader: downloader)
            } else if downloader.downloaderState == .waiting {
                ProgressView()
                    .frame(width: 25, height: 25)
                    .padding()
            } else if downloader.downloaderState == .downloading && downloader.percentComplete == 0.0 {
                ProgressView()
                    .frame(width: 25, height: 25)
                    .padding()
            } else if downloader.downloaderState == .success {
                Image(systemName: "arrow.down.circle.fill")
                    .frame(width: 20, height: 20)
                    .padding()
            } else {
                CircularProgressView(progress: downloader.percentComplete)
                    .frame(width: 20, height: 20)
                    .padding()
            }
        }
    }
}
