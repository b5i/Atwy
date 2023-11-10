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
    @State private var downloader: HLSDownloader?
    @State private var downloadURL: URL?
    @State var isShort: Bool = false
    @State var video: YTVideo
    @State var videoThumbnailData: Data? = nil
    @ObservedObject private var DCMM = DownloadCoordinatorManagerModel.shared
    var body: some View {
        VStack {
            if downloadURL != nil {
               Image(systemName: "arrow.down.circle.fill")
                   .frame(width: 20, height: 20)
            } else if let downloader = downloader {
                    if downloader.downloaderState == .inactive || downloader.downloaderState == .failed {
                        if downloader.downloaderState != .waiting && downloader.downloaderState != .downloading && downloader.downloaderState != .success {
                            DownloadVideoButtonView(video: video, isShort: isShort, videoThumbnailData: videoThumbnailData, downloader: downloader)
                        }
                    } else {
                        DownloadStateView(downloaded: (downloadURL != nil), video: video, isShort: isShort, downloader: downloader)
                    }
            } else {
                Button {
                    if let downloader = downloads.first(where: {$0.video?.videoId == video.videoId }) {
                        if downloader.downloaderState != .downloading && downloader.downloaderState != .success {
                            downloader.state.thumbnailData = videoThumbnailData
                            downloader.video = video
                            downloader.isShort = isShort
                            DCMM.appendDownloader(downloader: downloader)
                        }
                    } else {
                        let newDownloader = HLSDownloader()
                        newDownloader.state.thumbnailData = videoThumbnailData
                        newDownloader.video = video
                        newDownloader.isShort = isShort
                        DCMM.appendDownloader(downloader: newDownloader)
                        self.downloader = newDownloader
                    }
                } label: {
                    Image(systemName: "arrow.down")
                        .frame(width: 25, height: 25)
                        .padding()
                }
            }
        }
        .frame(width: 25, height: 25)
        .onAppear {
            reloadCoreData()
            NotificationCenter.default.addObserver(
                forName: Notification.Name("CoreDataChanged"),
                object: nil,
                queue: nil,
                using: { _ in
                    reloadCoreData()
                })
            if let downloader = downloads.first(where: {$0.video?.videoId == video.videoId}) {
                self.downloader = downloader
            } else {
                NotificationCenter.default.addObserver(forName: Notification.Name("DownloadingChanged\(video.videoId)"), object: nil, queue: nil, using: { _ in
                    if let downloader = downloads.first(where: {$0.video?.videoId == video.videoId}) {
                        self.downloader = downloader
                    }
                })
            }
        }
    }
    
    private func reloadCoreData() {
        self.downloadURL = URL(string: PersistenceModel.shared.getStorageLocationFor(video: video) ?? "")
    }
}
