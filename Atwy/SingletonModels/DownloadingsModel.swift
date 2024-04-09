//
//  DownloadingsModel.swift
//  Atwy
//
//  Created by Antoine Bollengier on 21.10.2023.
//

import Foundation
import UIKit
import Combine
import BackgroundTasks

class DownloadingsModel: ObservableObject, HLSDownloaderDelegate {
    static let shared = DownloadingsModel()
    
    @Published private(set) var downloadings: [String: HLSDownloader] = [:] // the video'id and its downloader
        
    let downloadersChangePublisher = PassthroughSubject<DownloadingsProgressAttributes.ContentState, Never>()
            
    var activeDownloadingsCount: Int {
         return activeDownloadings.count
    }
    
    var globalDownloadingsProgress: CGFloat {
        let downloadingsCount = activeDownloadingsCount
        guard downloadingsCount != 0 else { return 1 }

        let totalReceivedBytes = CGFloat(activeDownloadings.reduce(0, {$0 + $1.expectedBytes.receivedBytes}))
        let totalExpectedBytes = CGFloat(activeDownloadings.reduce(0, {$0 + $1.expectedBytes.totalBytes}))
        
        guard totalExpectedBytes != 0 else { return 1 }
        
        return CGFloat(max(min(totalReceivedBytes / totalExpectedBytes, 1), 0))
    }
    
    /// Downloading, waiting or paused downloader.
    var activeDownloadings: [HLSDownloader] {
        return downloadings.values.filter({$0.downloaderState == .downloading || $0.downloaderState == .waiting || $0.downloaderState == .paused})
    }
    
    /// Waiting downloaders.
    var waitingDownloadings: [HLSDownloader] {
        return downloadings.values.filter({
            $0.downloaderState == .waiting
        })
    }
    
    init() {
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil, using: { _ in
            self.refreshDownloadingsProgress()
        })
    }
    
    public func refreshDownloadingsProgress() {
        for activeDownloading in self.activeDownloadings {
            activeDownloading.refreshProgress()
        }
    }
    
    /// If ``downloadings`` already contains a downloader whose videoId is identical to the one that's going to be appended, it will be replaced by the new one.
    public func addDownloader(_ downloader: HLSDownloader) {
        downloader.delegate = self
        DispatchQueue.main.async {
            self.downloadings.updateValue(downloader, forKey: downloader.video.videoId)
            downloader.downloaderState = .waiting // fires launchDownloads
            NotificationCenter.default.post(name: .atwyDownloadingChanged(for: downloader.video.videoId), object: nil)
        }
    }
        
    public func cancelDownloadFor(videoId: String) {
        if let downloader = self.downloadings[videoId] {
            self.cancelDownloadFor(downloader: downloader)
        }
    }
    
    /// If the downloader is present in ``downloadings``, it will be removed from it and cancelled.
    public func cancelDownloadFor(downloader: HLSDownloader) {
        self.removeDownloader(downloader: downloader)
        PopupsModel.shared.showPopup(.cancelledDownload, data: downloader.state.thumbnailData)
    }
    
    public func removeDownloader(downloader: HLSDownloader) {
        downloader.cancelDownload()
        downloader.delegate = nil
        self.downloadings.removeValue(forKey: downloader.video.videoId)
        NotificationCenter.default.post(name: .atwyDownloadingChanged(for: downloader.video.videoId), object: nil)
        self.launchDownloads()
    }

    public func launchDownloads() {
        var activeDownloaders = downloadings.count
        for waitingDownloading in waitingDownloadings {
            guard activeDownloaders < 3 else { break }
            waitingDownloading.downloadVideo()
            activeDownloaders += 1
            if #available(iOS 16.1, *), LiveActivitesManager.shared.activities[.downloadingsProgress] == nil {
                DownloadingsProgressActivity.setupOnManager(attributes: .init(), state: .modelState)
            }
        }
        if activeDownloadingsCount == 0 {
            NotificationCenter.default.post(name: .atwyNoDownloadingsLeft, object: nil)
            self.updatePublisher()
        }
    }
    
    public func percentageChanged(_ newPercentage: CGFloat, downloader: HLSDownloader) {
        self.updatePublisher()
    }
    
    private func updatePublisher() {
        self.downloadersChangePublisher.send(.modelState)
    }
}
