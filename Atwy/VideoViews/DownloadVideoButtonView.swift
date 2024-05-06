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
    let video: YTVideo
    let videoThumbnailData: Data?
    @Binding var downloader: HLSDownloader?
    @ObservedObject private var DM = DownloadingsModel.shared
    var body: some View {
        Button {
            if let currentDownloader = downloader {
                DM.removeDownloader(downloader: currentDownloader)
            }
            let newDownloader = HLSDownloader(video: video)
            newDownloader.state.thumbnailData = videoThumbnailData
            DM.addDownloader(newDownloader)
            self.downloader = newDownloader
        } label: {
            Image(systemName: "arrow.down")
                .frame(width: 25, height: 25)
                .padding()
        }
    }
}
