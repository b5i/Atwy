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
        downloads.append(downloader)
        downloader.downloaderState = .waiting // fires launchDownloads
        NotificationCenter.default.post(name: Notification.Name("DownloadingChanged\(downloader.video?.videoId ?? "")"), object: nil)
    }

    func launchDownloads() {
        if downloadings.count < 3 {
            downloads.first(where: {
                $0.downloaderState == .waiting
            })?.downloadVideo()
            if downloadings.count + pausedDownloadings.count + waitingDownloadings.count == 0 {
                NotificationCenter.default.post(name: Notification.Name("NoDownloadingsLeft"), object: nil)
            }
        }
        NotificationCenter.default.post(name: Notification.Name("DownloadingChanged"), object: nil)
    }
}