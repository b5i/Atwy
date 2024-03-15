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

protocol HLSDownloaderDelegate {
    func percentageChanged(_ newPercentage: CGFloat, downloader: HLSDownloader)
}

class HLSDownloader: NSObject, ObservableObject, Identifiable {

    let video: YTVideo
    var delegate: HLSDownloaderDelegate? = nil
    @Published var state = Download()

    @Published var downloaderState: HLSDownloaderState = .inactive {
        didSet {
            switch downloaderState {
            case .waiting:
                DownloadingsModel.shared.launchDownloads()
            case .failed, .success:
                DownloadingsModel.shared.removeDownloader(downloader: self)
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
    
    let creationDate = Date()
    var location: URL?
    var isFavorite: Bool?
    var videoDescription: String?
    var isShort: Bool = false
    var downloadTask: URLSessionTask?
//    var downloadTask: AVAggregateAssetDownloadTask?
    var downloadData: (any DownloadFormat)?
    var startedEndProcedure: Bool = false
    @Published var downloadTaskState: URLSessionTask.State = .canceling

    init(video: YTVideo) {
        self.video = video
        super.init()
    }
    
    public func refreshProgress() {
        guard let downloadTask = downloadTask else { return }
        
        guard downloadTask.countOfBytesExpectedToReceive != 0 && downloadTask.countOfBytesExpectedToReceive != NSURLSessionTransferSizeUnknown else { return }
        
        self.expectedBytes = (Int(downloadTask.countOfBytesReceived), Int(downloadTask.countOfBytesExpectedToReceive))
        
        
        let newPercentage = max(Double(downloadTask.countOfBytesReceived / downloadTask.countOfBytesExpectedToReceive), self.percentComplete)
        DispatchQueue.main.async {
            self.percentComplete = newPercentage
        }
    }
    
    func downloadVideo(thumbnailData: Data? = nil, videoDescription: String = "") {
        guard self.downloaderState != .downloading else { return }
        DispatchQueue.main.async {
            self.downloaderState = .downloading
        }
        state.title = ""
        state.owner = ""
        state.location = ""
        expectedBytes = (0, 0)
        percentComplete = 0.0
        location = nil
        self.videoDescription = nil
        if let downloadURL = downloadData?.url {
            downloadHLS(downloadURL: downloadURL, videoDescription: videoDescription, video: video, thumbnailData: thumbnailData)
        } else {
            self.video.fetchStreamingInfos(youtubeModel: YTM, infos: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let response):
                    if let streamingURL = response.streamingURL {
                        self.downloadHLS(downloadURL: streamingURL, videoDescription: response.videoDescription ?? "", video: self.video, thumbnailData: thumbnailData)
                    } else {
                        print("Couldn't get video streaming url.")
                        DispatchQueue.main.async {
                            self.downloaderState = .failed
                            NotificationCenter.default.post(name: .atwyDownloadingsChanged, object: nil)
                        }
                    }
                case .failure(let error):
                    print("Couldn't get video streaming data, error: \(String(describing: error)).")
                    DispatchQueue.main.async {
                        self.downloaderState = .failed
                        NotificationCenter.default.post(name: .atwyDownloadingsChanged, object: nil)
                    }
                }
            })
        }
    }

    func downloadHLS(downloadURL: URL, videoDescription: String, video: YTVideo, thumbnailData: Data? = nil) {
        func launchDownload(thumbnailData: Data, isHLS: Bool) {
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
                //                        print("Couldn't load preferredMediaSelection.")
                //                    }
                //                }
                if let downloadTask = assetDownloadURLSession.makeAssetDownloadTask(
                    asset: AVURLAsset(url: downloadURL),
                    assetTitle: video.title ?? "No title",
                    assetArtworkData: thumbnailData
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
        
        let backgroundConfiguration = URLSessionConfiguration.background(
            withIdentifier: UUID().uuidString) // !!!!!!!!!!!!!!! il doit être différent pour chaque download !
        let assetDownloadURLSession = AVAssetDownloadURLSession(
            configuration: backgroundConfiguration,
            assetDownloadDelegate: self,
            delegateQueue: OperationQueue.main
        )
        
        self.videoDescription = videoDescription
        let isHLS = downloadURL.absoluteString.contains("manifest.googlevideo.com")
        
        if let thumbnailData = self.state.thumbnailData {
            launchDownload(thumbnailData: thumbnailData, isHLS: isHLS)
        } else if let thumbnailData = thumbnailData {
            launchDownload(thumbnailData: thumbnailData, isHLS: isHLS)
        } else {
            if let thumbnailURL = video.thumbnails.last?.url ?? URL(string: "https://i.ytimg.com/vi/\(video.videoId)/hqdefault.jpg") {
                getImage(from: thumbnailURL) { (imageData, _, error) in
                    guard let imageData = imageData, error == nil else { print("Could not download image"); DispatchQueue.main.async { self.downloaderState = .failed; }; return }
                    DispatchQueue.main.async {
                        self.state.thumbnailData = imageData
                    }
                    launchDownload(thumbnailData: imageData, isHLS: isHLS)
                }
            } else {
                print("No image")
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
            self.downloadTaskState = self.downloadTask!.state
            self.downloaderState = .paused
            NotificationCenter.default.post(name: .atwyDownloadingsChanged, object: nil)
        }
    }

    func resumeDownload() {
        DispatchQueue.main.async {
            self.downloadTask?.resume()
            self.downloadTaskState = self.downloadTask!.state
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
