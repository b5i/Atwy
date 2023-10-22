//
//  DownloadingItemsContextMenuView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 28.01.23.
//

import SwiftUI

struct DownloadingItemsContextMenuView: View {
    @StateObject var downloader: HLSDownloader
    var body: some View {
        if downloader.downloadTask?.state == .suspended {
            Button {
                downloader.resumeDownload()
                PopupsModel.shared.showPopup(.resumedDownload, data: downloader.state.thumbnailData)
            } label: {
                HStack {
                    Text("Resume Download")
                    Image(systemName: "play")
                }
            }
        } else if downloader.downloadTask?.state == .running {
            Button {
                downloader.pauseDownload()
                PopupsModel.shared.showPopup(.pausedDownload, data: downloader.state.thumbnailData)
            } label: {
                HStack {
                    Text("Pause Download")
                    Image(systemName: "pause")
                }
            }
        }
        Button(role: .destructive) {
            withAnimation {
                downloader.cancelDownload()
                downloads.removeAll(where: {$0.video?.videoId == downloader.video!.videoId})
                DownloadCoordinatorManagerModel.shared.launchDownloads()
            }
            PopupsModel.shared.showPopup(.cancelledDownload, data: downloader.state.thumbnailData)
        } label: {
            HStack {
                Text("Cancel Download")
                Image(systemName: "trash")
            }
        }
    }
}
