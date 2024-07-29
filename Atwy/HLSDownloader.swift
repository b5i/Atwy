//
//  HLSDownloader.swift
//  Atwy
//
//  Created by Antoine Bollengier on 26.11.22.
//

import Foundation
import AVFoundation
import CoreData
import SwiftUI
import YouTubeKit
import OSLog

protocol HLSDownloaderDelegate {
    func percentageChanged(_ newPercentage: CGFloat, downloader: HLSDownloader)
}

class HLSDownloader: NSObject, ObservableObject, Identifiable {

    var delegate: HLSDownloaderDelegate? = nil
    @Published var downloadInfo: DownloadInfo

    @Published var downloaderState: HLSDownloaderState = .inactive {
        didSet {
            switch downloaderState {
            case .waiting:
                DownloadersModel.shared.launchDownloaders()
            case .failed, .success:
                DownloadersModel.shared.removeDownloader(downloader: self)
            case .inactive, .paused, .downloading:
                break
            }
        }
    }
    @Published var percentComplete: Double = 0.0
    
    var expectedBytes: (receivedBytes: Int, totalBytes: Int) = (0, 0) {
        didSet {
            self.delegate?.percentageChanged(percentComplete, downloader: self)
        }
    }
    
    var isFavorite: Bool?
    var downloadTask: URLSessionTask?
//    var downloadTask: AVAggregateAssetDownloadTask?
    var downloadData: (any DownloadFormat)?
    var startedEndProcedure: Bool = false
    @Published var downloadTaskState: URLSessionTask.State = .canceling

    init(video: YTVideo) {
        self.downloadInfo = DownloadInfo(video: video)
        super.init()
    }
    
    func refreshProgress() {
        guard let downloadTask = downloadTask else { return }
        
        guard downloadTask.countOfBytesExpectedToReceive != 0 && downloadTask.countOfBytesExpectedToReceive != NSURLSessionTransferSizeUnknown else { return }
        
        self.expectedBytes = (Int(downloadTask.countOfBytesReceived), Int(downloadTask.countOfBytesExpectedToReceive))
        
        
        let newPercentage = max(Double(downloadTask.countOfBytesReceived / downloadTask.countOfBytesExpectedToReceive), self.percentComplete)
        DispatchQueue.main.async {
            self.percentComplete = newPercentage
        }
    }
    
    func downloadVideo() {
        guard self.downloaderState != .downloading else { return }
        DispatchQueue.main.async {
            self.downloaderState = .downloading
        }
        
        downloadInfo.downloadLocation = nil
        expectedBytes = (0, 0)
        percentComplete = 0.0
        self.downloadInfo.videoDescription = nil
        if let downloadURL = downloadData?.url {
            downloadHLS(downloadURL: downloadURL)
        } else {
            self.downloadInfo.video.fetchStreamingInfos(youtubeModel: YTM, infos: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let response):
                    if let streamingURL = response.streamingURL {
                        self.downloadHLS(downloadURL: streamingURL)
                    } else {
                        Logger.atwyLogs.simpleLog("Couldn't get video streaming url.")
                        DispatchQueue.main.async {
                            self.downloaderState = .failed
                            NotificationCenter.default.post(name: .atwyDownloadingsChanged, object: nil)
                        }
                    }
                case .failure(let error):
                    Logger.atwyLogs.simpleLog("Couldn't get video streaming data, error: \(error.localizedDescription).")
                    DispatchQueue.main.async {
                        self.downloaderState = .failed
                        NotificationCenter.default.post(name: .atwyDownloadingsChanged, object: nil)
                    }
                }
            })
        }
    }

    private func downloadHLS(downloadURL: URL) {
        func launchDownload(isHLS: Bool) {
            Task {
                if #available(iOS 16.1, *) {
                    let activity = DownloaderProgressActivity(downloader: self)
                    activity.setupOnManager(attributes: .init(), state: activity.getNewData())
                }
                
                let infos = try? await self.downloadInfo.video.fetchMoreInfosThrowing(youtubeModel: YTM)
                DispatchQueue.main.sync {
                    self.downloadInfo.videoInfo = infos
                }
                
                for chapter in self.downloadInfo.videoInfo?.chapters ?? [] {
                    guard let startTimeSeconds = chapter.startTimeSeconds else { continue }
                    var chapterEntity = DownloadedVideoChapter.NonEntityDownloadedVideoChapter(startTimeSeconds: Int32(startTimeSeconds), shortTimeDescription: chapter.timeDescriptions.shortTimeDescription)
                    if let chapterThumbnailURL = chapter.thumbnail.last?.url {
                        let imageTask = DownloadImageOperation(imageURL: chapterThumbnailURL)
                        imageTask.start()
                        imageTask.waitUntilFinished()
                        chapterEntity.thumbnail = imageTask.imageData
                    } else {
                        chapterEntity.thumbnail = self.downloadInfo.thumbnailData
                    }
                    chapterEntity.title = chapter.title
                    
                    DispatchQueue.main.sync {
                        self.downloadInfo.chapters.append(chapterEntity)
                    }
                }
                
                if let channelThumbnailURL = self.downloadInfo.videoInfo?.channel?.thumbnails.maxFor(3) ?? self.downloadInfo.video.channel?.thumbnails.maxFor(3) {
                    let imageTask = DownloadImageOperation(imageURL: channelThumbnailURL.url)
                    imageTask.start()
                    imageTask.waitUntilFinished()
                    DispatchQueue.main.sync {
                        self.downloadInfo.channelThumbnailData = imageTask.imageData
                    }
                }
                
                if isHLS {
                    //                Task {
                    //                    do {
                    //                        let preferredMediaSelection = try await asset.load(.preferredMediaSelection)
                    //                        if let downloadTask = assetDownloadURLSession.aggregateAssetDownloadTask(with: asset, mediaSelections: [], assetTitle: video.title ?? "No title", assetArtworkData: thumbnailData) {
                    //                            downloadTask.resume()
                    //                            self.downloadTask?.cancel()
                    //                            DispatchQueue.main.async {
                    //                                self.downloadTask = downloadTask
                    //                                self.downloadTaskState = downloadTask.state
                    //                            }
                    //                        }
                    //                    } catch {
                    //                        Logger.atwyLogs.simpleLog("Couldn't load preferredMediaSelection.")
                    //                    }
                    //                }
                    if let downloadTask = assetDownloadURLSession.makeAssetDownloadTask(
                        asset: AVURLAsset(url: downloadURL),
                        assetTitle: downloadInfo.video.title ?? "No title",
                        assetArtworkData: downloadInfo.thumbnailData
                    ) {
                        downloadTask.resume()
                        self.downloadTask?.cancel()
                        DispatchQueue.main.async {
                            self.downloadTask = downloadTask
                            self.downloadTaskState = downloadTask.state
                        }
                    }
                } else {
                    var downloadRequest = URLRequest(url: downloadURL)
                    downloadRequest.setValue("bytes=0-", forHTTPHeaderField: "Range")
                    let downloadTask = URLSession.shared.downloadTask(with: downloadRequest)
                    downloadTask.delegate = self
                    downloadTask.resume()
                    self.downloadTask?.cancel()
                    DispatchQueue.main.async {
                        self.downloadTask = downloadTask
                        self.downloadTaskState = downloadTask.state
                    }
                }
                self.startedEndProcedure = false
            }
        }

        let backgroundConfiguration = URLSessionConfiguration.background(
            withIdentifier: UUID().uuidString) // !!!!!!!!!!!!!!! il doit être différent pour chaque download !
        let assetDownloadURLSession = AVAssetDownloadURLSession(
            configuration: backgroundConfiguration,
            assetDownloadDelegate: self,
            delegateQueue: nil
        )
                        
        let isHLS = downloadURL.absoluteString.contains("manifest.googlevideo.com")
        
        DispatchQueue.main.sync {
            self.downloadInfo.thumbnailURL = downloadInfo.video.thumbnails.last?.url ?? URL(string: "https://i.ytimg.com/vi/\(downloadInfo.video.videoId)/hqdefault.jpg")
        }
        
        if self.downloadInfo.thumbnailData != nil {
            launchDownload(isHLS: isHLS)
        } else {
            if let thumbnailURL = downloadInfo.thumbnailURL {
                getImage(from: thumbnailURL) { (imageData, _, error) in
                    /*
                     let imageTask = DownloadImageOperation(imageURL: thumbnailURL)
                     imageTask.start()
                     imageTask.waitUntilFinished()
                     */
                    guard let imageData = imageData, error == nil else { Logger.atwyLogs.simpleLog("Could not download image"); DispatchQueue.main.async { self.downloaderState = .failed; }; return }
                    DispatchQueue.main.sync {
                        self.downloadInfo.thumbnailData = imageData
                    }
                    launchDownload(isHLS: isHLS)
                }
            } else {
                Logger.atwyLogs.simpleLog("No image")
                DispatchQueue.main.async {
                    self.downloaderState = .failed
                    NotificationCenter.default.post(name: .atwyDownloadingsChanged, object: nil)
                }
                return
            }
        }
    }
    
    func pauseDownload() {
        DispatchQueue.main.async {
            self.downloadTask?.suspend()
            self.downloadTaskState = self.downloadTask?.state ?? .suspended
            self.downloaderState = .paused
            NotificationCenter.default.post(name: .atwyDownloadingsChanged, object: nil)
        }
    }

    func resumeDownload() {
        DispatchQueue.main.async {
            self.downloadTask?.resume()
            self.downloadTaskState = self.downloadTask?.state ?? .suspended
            self.downloaderState = .downloading
            NotificationCenter.default.post(name: .atwyDownloadingsChanged, object: nil)
        }
    }

    func cancelDownload() {
        DispatchQueue.main.async {
            self.downloadTask?.cancel()
            if let downloadTaskState = self.downloadTask?.state {
                self.downloadTaskState = downloadTaskState
            }
            self.downloaderState = .inactive
        }
    }
    
    struct DownloadInfo {
        let video: YTVideo
        let timestamp = Date()
        var videoInfo: MoreVideoInfosResponse?
        var chapters: [DownloadedVideoChapter.NonEntityDownloadedVideoChapter] = []
        var thumbnailData: Data?
        var thumbnailURL: URL?
        var channelThumbnailData: Data?
        var videoDescription: String?
        var downloadLocation: URL?
    }

    enum HLSDownloaderState: Equatable {
        /// The downloader successfully downloaded its video.
        case success
        
        /// The downloader is waiting for download slots to open.
        case waiting
        
        /// The downloader is actively downloading its video.
        case downloading
        
        /// The downloader is paused.
        case paused
        
        /// The downloader failed to download its video.
        case failed
        
        /// The download has been canceled and the downloader does nothing.
        case inactive
    }
}
