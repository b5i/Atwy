//
//  DownloadVideoButtonView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 23.04.23.
//

import SwiftUI
import YouTubeKit

struct DownloadVideoButtonView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State var video: YTVideo
    @State var isShort: Bool = false
    @State var videoThumbnailData: Data?
    @Binding var downloader: HLSDownloader?
    var body: some View {
        Button {
            if let downloader = downloads.first(where: {$0.video?.videoId == video.videoId}) {
                if downloader.downloaderState != .downloading && downloader.downloaderState != .success {
                    loadDownloaderWithVideo(downloader: downloader)
                }
            } else {
                let newDownloader = HLSDownloader()
                loadDownloaderWithVideo(downloader: newDownloader)
                self.downloader = newDownloader
            }
        } label: {
            Image(systemName: "arrow.down")
                .frame(width: 25, height: 25)
                .padding()
        }
    }
    
    private func loadDownloaderWithVideo(downloader: HLSDownloader) {
        downloader.state.thumbnailData = videoThumbnailData
        downloader.video = video
        downloader.isShort = isShort
        DownloadCoordinatorManagerModel.shared.appendDownloader(downloader: downloader)
    }
}
