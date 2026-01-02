//
//  DownloadSwipeActionsView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 28.01.23.
//  Copyright © 2023-2026 Antoine Bollengier. All rights reserved.
//

import SwiftUI

struct DownloadSwipeActionsView: View {
    @ObservedObject var downloader: HLSDownloader
    var body: some View {
        Button {
            if downloader.downloaderState != .downloading && downloader.downloaderState != .failed {
                downloader.resumeDownload()
                PopupsModel.shared.showPopup(.resumedDownload, data: downloader.downloadInfo.thumbnailData)
            } else if downloader.downloaderState == .downloading {
                downloader.pauseDownload()
                PopupsModel.shared.showPopup(.pausedDownload, data: downloader.downloadInfo.thumbnailData)
            }
        } label: {
            ZStack {
                Rectangle()
                    .tint(.orange)
                Image(systemName: downloader.downloaderState == .downloading ? "pause" : "play")
            }
        }
        .tint(.orange)
        Button {
            DownloadersModel.shared.cancelDownloadFor(downloader: downloader)
        } label: {
            ZStack {
                Rectangle()
                    .tint(.red)
                Image(systemName: "trash")
            }
        }
        .tint(.red)
    }
}
