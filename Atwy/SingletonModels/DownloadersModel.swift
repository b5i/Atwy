//
//  DownloadersModel.swift
//  Atwy
//
//  Created by Antoine Bollengier on 21.10.2023.
//  Copyright © 2023-2025 Antoine Bollengier. All rights reserved.
//

import Foundation
import UIKit
import Combine
import BackgroundTasks

class DownloadersModel: ObservableObject, HLSDownloaderDelegate {
    static let shared = DownloadersModel()
        
    @Published private(set) var downloaders: [String: HLSDownloader] = [:] // the video'id and its downloader
        
    let downloadersChangePublisher = PassthroughSubject<Bool, Never>()
    
    var globalDownloadingsProgress: CGFloat {
        let downloadingsCount = activeDownloaders.count
        guard downloadingsCount != 0 else { return 1 }

        let totalReceivedBytes = CGFloat(activeDownloaders.reduce(0, {$0 + $1.expectedBytes.receivedBytes}))
        let totalExpectedBytes = CGFloat(activeDownloaders.reduce(0, {$0 + $1.expectedBytes.totalBytes}))
        
        guard totalExpectedBytes != 0 else { return 1 }
        
        return CGFloat(max(min(totalReceivedBytes / totalExpectedBytes, 1), 0))
    }
    
    /// Downloading, waiting or paused downloaders.
    var activeDownloaders: [HLSDownloader] {
        return downloaders.values.filter {
            $0.downloaderState == .downloading || $0.downloaderState == .waiting || $0.downloaderState == .paused
        }
    }
    
    /// Downloading downloaders.
    var downloadingDownloaders: [HLSDownloader] {
        return downloaders.values.filter {
            $0.downloaderState == .downloading
        }
    }
    
    /// Waiting downloaders.
    var waitingDownloaders: [HLSDownloader] {
        return downloaders.values.filter {
            $0.downloaderState == .waiting
        }
    }
    
    /// Paused downloaders.
    var pausedDownloaders: [HLSDownloader] {
        return downloaders.values.filter {
            $0.downloaderState == .paused
        }
    }
    
    init() {
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil, using: { _ in
            self.refreshDownloadingsProgress()
        })
    }
    
    public func refreshDownloadingsProgress() {
        for activeDownloading in self.activeDownloaders {
            activeDownloading.refreshProgress()
        }
    }
    
    /// If ``downloadings`` already contains a downloader whose videoId is identical to the one that's going to be appended, it will be replaced by the new one.
    public func addDownloader(_ downloader: HLSDownloader) {
        downloader.delegate = self
        DispatchQueue.main.async {
            self.downloaders.updateValue(downloader, forKey: downloader.downloadInfo.video.videoId)
            downloader.downloaderState = .waiting // fires launchDownloads
            NotificationCenter.default.post(name: .atwyDownloadingChanged(for: downloader.downloadInfo.video.videoId), object: nil)
        }
    }
        
    public func cancelDownloadFor(videoId: String) {
        if let downloader = self.downloaders[videoId] {
            self.cancelDownloadFor(downloader: downloader)
        }
    }
    
    /// If the downloader is present in ``downloadings``, it will be removed from it and cancelled.
    public func cancelDownloadFor(downloader: HLSDownloader) {
        self.removeDownloader(downloader: downloader)
        PopupsModel.shared.showPopup(.cancelledDownload, data: downloader.downloadInfo.thumbnailData)
    }
    
    public func removeDownloader(downloader: HLSDownloader) {
        self.downloaders.removeValue(forKey: downloader.downloadInfo.video.videoId)
        downloader.cancelDownload()
        downloader.delegate = nil
        NotificationCenter.default.post(name: .atwyDownloadingChanged(for: downloader.downloadInfo.video.videoId), object: nil)
        self.launchDownloaders()
    }

    public func launchDownloaders(_ concurrentDownloadsLimit: Int? = nil) {
        var activeDownloadersCount = downloadingDownloaders.count
        for pausedDownloader in pausedDownloaders.sorted(by: { $0.downloadInfo.timestamp < $1.downloadInfo.timestamp }) {
            guard activeDownloadersCount < concurrentDownloadsLimit ?? PreferencesStorageModel.shared.concurrentDownloadsLimit else { break }
            pausedDownloader.resumeDownload()
            activeDownloadersCount += 1
        }
        for waitingDownloader in waitingDownloaders.sorted(by: { $0.downloadInfo.timestamp < $1.downloadInfo.timestamp }) {
            guard activeDownloadersCount < concurrentDownloadsLimit ?? PreferencesStorageModel.shared.concurrentDownloadsLimit else { break }
            Task {
                await waitingDownloader.downloadVideo()
            }
            activeDownloadersCount += 1
        }
        if activeDownloadersCount == 0 {
            NotificationCenter.default.post(name: .atwyNoDownloadingsLeft, object: nil)
        }
        self.updatePublisher()
    }
    
    public func maxConcurrentDownloadsChanged(_ newValue: Int) {
        if downloadingDownloaders.count < newValue {
            launchDownloaders(newValue)
        } else {
            downloadingDownloaders.dropLast(newValue).forEach { $0.pauseDownload() }
        }
    }
    
    public func percentageChanged(_ newPercentage: CGFloat, downloader: HLSDownloader) {
        self.updatePublisher()
    }
    
    private func updatePublisher() {
        self.downloadersChangePublisher.send(true)
    }
}
