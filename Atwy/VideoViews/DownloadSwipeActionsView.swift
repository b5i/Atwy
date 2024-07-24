//
//  DownloadSwipeActionsView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 28.01.23.
//

import SwiftUI

struct DownloadSwipeActionsView: View {
    @ObservedObject var downloader: HLSDownloader
    var body: some View {
        Button {
            if downloader.downloadTask?.state == .suspended {
                downloader.resumeDownload()
                PopupsModel.shared.showPopup(.resumedDownload, data: downloader.state.thumbnailData)
            } else {
                downloader.pauseDownload()
                PopupsModel.shared.showPopup(.pausedDownload, data: downloader.state.thumbnailData)
            }
        } label: {
            ZStack {
                Rectangle()
                    .tint(.orange)
                Image(systemName: downloader.downloadTask?.state == .suspended ? "play" : "pause")
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
