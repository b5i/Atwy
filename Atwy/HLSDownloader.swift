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

class HLSDownloader: NSObject, ObservableObject {

    @Published var video: YTVideo?
    @Published var state = Download()

    var DCMM = DownloadCoordinatorManagerModel.shared

    @Published var downloaderState: HLSDownloaderState = .inactive {
        didSet (newValue) {
            switch newValue {
            case .waiting:
                break
            case .downloading:
                break
            case .failed:
                if let videoId = self.video?.videoId {
                    downloads.removeAll(where: {$0.video?.videoId == videoId})
                }
                fallthrough
            case .inactive, .success, .paused:
                DCMM.launchDownloads()
            }
        }
    }
    @Published var percentComplete: Double = 0.0
    var location: URL?
    var isFavorite: Bool?
    var videoDescription: String?
    var isShort: Bool = false
    var downloadTask: URLSessionTask?
//    var downloadTask: AVAggregateAssetDownloadTask?
    var downloadData: (any DownloadFormat)?
    var startedEndProcedure: Bool = false
    @Published var downloadTaskState: URLSessionTask.State = .canceling

    override init() {
        super.init()
    }
    
    public func refreshProgress() {
        guard let downloadTask = downloadTask else { return }
        
        guard downloadTask.countOfBytesExpectedToReceive != 0 && downloadTask.countOfBytesExpectedToReceive != NSURLSessionTransferSizeUnknown else { return }
        DispatchQueue.main.async {
            self.percentComplete = max(Double(downloadTask.countOfBytesReceived / downloadTask.countOfBytesExpectedToReceive), self.percentComplete)
        }
    }
    
    func downloadVideo(thumbnailData: Data? = nil, videoDescription: String = "") {
        guard self.downloaderState != .downloading else { return }
        DispatchQueue.main.async {
            self.downloaderState = .downloading
        }
        if let video = video {
            state.title = ""
            state.owner = ""
            state.location = ""
            percentComplete = 0.0
            location = nil
            self.videoDescription = nil
            if let downloadURL = downloadData?.url {
                downloadHLS(downloadURL: downloadURL, videoDescription: videoDescription, video: video, thumbnailData: thumbnailData)
            } else {
                self.video?.fetchStreamingInfos(youtubeModel: YTM, infos: { result in
                    switch result {
                    case .success(let response):
                        if let streamingURL = response.streamingURL {
                            self.downloadHLS(downloadURL: streamingURL, videoDescription: response.videoDescription ?? "", video: video, thumbnailData: thumbnailData)
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
        } else {
            DispatchQueue.main.async {
                self.downloaderState = .failed
                DownloadCoordinatorManagerModel.shared.launchDownloads()
            }
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
            if self.downloadTask != nil {
                self.downloadTaskState = self.downloadTask!.state
            }
            self.downloaderState = .inactive
            NotificationCenter.default.post(name: .atwyDownloadingsChanged, object: nil)
        }
    }

    enum HLSDownloaderState: Equatable {
        case success
        case waiting
        case downloading
        case paused
        case failed
        case inactive
    }
}
