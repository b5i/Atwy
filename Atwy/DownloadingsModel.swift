//
//  DownloadingsModel.swift
//  Atwy
//
//  Created by Antoine Bollengier on 21.10.2023.
//

import Foundation
import SwiftUI

var downloads: [HLSDownloader] = [] {
    didSet {
        NotificationCenter.default.post(name: Notification.Name("DownloadingChanged"), object: nil)
    }
}

class DownloadingsModel: ObservableObject {
    
    static let shared = DownloadingsModel()
    
    @Published var downloadings = downloads
    
    var activeDownloadings: Int {
         return downloadings.filter({$0.downloaderState == .downloading || $0.downloaderState == .waiting || $0.downloaderState == .paused}).count
    }
    
    init() {
        NotificationCenter.default.addObserver(forName: Notification.Name("DownloadingChanged"), object: nil, queue: nil, using: { _ in
            DispatchQueue.main.async {
                self.downloadings = downloads
            }
        })
    }
        
    public func cancelDownloadFor(_ videoId: String) {
        let downloaders = downloadings.filter({$0.video?.videoId == videoId})
        for downloader in downloaders {
            withAnimation {
                downloader.cancelDownload()
                downloads.removeAll(where: {$0.video?.videoId == downloader.video!.videoId})
                DownloadCoordinatorManagerModel.shared.launchDownloads()
            }
            PopupsModel.shared.showPopup(.cancelledDownload, data: downloader.state.thumbnailData)
        }
    }
}
