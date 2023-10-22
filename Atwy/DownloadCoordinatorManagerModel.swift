//
//  DownloadCoordinatorManagerModel.swift
//  Atwy
//
//  Created by Antoine Bollengier on 27.01.23.
//

import Foundation

class DownloadCoordinatorManagerModel: ObservableObject {

    static let shared = DownloadCoordinatorManagerModel()

    var downloadings: [HLSDownloader] {
        downloads.filter({
            $0.downloaderState == .downloading
        })
    }

    var pausedDownloadings: [HLSDownloader] {
        downloads.filter({
            $0.downloaderState == .paused
        })
    }

    var waitingDownloadings: [HLSDownloader] {
        downloads.filter({
            $0.downloaderState == .waiting
        })
    }

    func appendDownloader(downloader: HLSDownloader) {
        downloader.downloaderState = .waiting
        downloads.append(downloader)
        NotificationCenter.default.post(name: Notification.Name("DownloadingChanged\(downloader.video?.videoId ?? "")"), object: nil)
        if downloadings.count < 3 {
            downloader.downloadVideo()
        }
    }

    func launchDownloads() {
        if downloadings.count < 3 {
            downloads.first(where: {
                $0.downloaderState == .waiting
            })?.downloadVideo()
            if downloadings.count + pausedDownloadings.count == 0 {
                NotificationCenter.default.post(name: Notification.Name("NoDownloadingsLeft"), object: nil)
            }
        }
        NotificationCenter.default.post(name: Notification.Name("DownloadingChanged"), object: nil)
    }
}
