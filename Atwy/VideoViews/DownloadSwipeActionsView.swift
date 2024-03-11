//
//  DownloadSwipeActionsView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 28.01.23.
//

import SwiftUI

struct DownloadSwipeActionsView: View {
    @StateObject var downloader: HLSDownloader
    var body: some View {
        if downloader.downloadTask?.state == .suspended {
            Button {
                downloader.resumeDownload()
                PopupsModel.shared.showPopup(.resumedDownload, data: downloader.state.thumbnailData)
            } label: {
                ZStack {
                    Rectangle()
                        .tint(.orange)
                    Image(systemName: "play")
                        .tint(.white)
                }
            }
            .tint(.orange)
        } else if downloader.downloadTask?.state == .running {
            Button {
                downloader.pauseDownload()
                PopupsModel.shared.showPopup(.pausedDownload, data: downloader.state.thumbnailData)
            } label: {
                ZStack {
                    Rectangle()
                        .tint(.orange)
                    Image(systemName: "pause")
                        .tint(.white)
                }
            }
            .tint(.orange)
        }
        Button {
            withAnimation {
                downloader.cancelDownload()
                downloads.removeAll(where: {$0.video?.videoId == downloader.video!.videoId})
                DownloadCoordinatorManagerModel.shared.launchDownloads()
                PopupsModel.shared.showPopup(.cancelledDownload, data: downloader.state.thumbnailData)
            }
        } label: {
            ZStack {
                Rectangle()
                    .tint(.red)
                Image(systemName: "trash")
                    .tint(.white)
            }
        }
        .tint(.red)
    }
}
