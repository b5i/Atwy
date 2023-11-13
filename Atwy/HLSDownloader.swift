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
    var downloadTask: AVAssetDownloadTask?
    var downloadData: (any DownloadFormat)?
    @Published var downloadTaskState: URLSessionTask.State = .canceling

    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updatePercentage),
            name: Notification.Name("DownloadPercentageChanged"),
            object: nil
        )
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
                self.video?.fetchStreamingInfos(youtubeModel: YTM, infos: { response, error in
                    if let streamingURL = response?.streamingURL {
                        self.downloadHLS(downloadURL: streamingURL, videoDescription: response?.videoDescription ?? "", video: video, thumbnailData: thumbnailData)
                    } else {
                        DispatchQueue.main.async {
                            self.downloaderState = .failed
                            NotificationCenter.default.post(name: Notification.Name("DownloadingChanged"), object: nil)
                        }
                        print("Couldn't get video streaming data, error: \(String(describing: error)).")
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
        func launchDownload(thumbnailData: Data) {
            if let downloadTask = assetDownloadURLSession.makeAssetDownloadTask(
                asset: hlsAsset,
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
        }
        
        let backgroundConfiguration = URLSessionConfiguration.background(
            withIdentifier: UUID().uuidString) // !!!!!!!!!!!!!!! il doit être différent pour chaque download !
        let assetDownloadURLSession = AVAssetDownloadURLSession(
            configuration: backgroundConfiguration,
            assetDownloadDelegate: self,
            delegateQueue: OperationQueue.main
        )
        
        let url = downloadURL
        self.videoDescription = videoDescription
        let hlsAsset: AVURLAsset
        if downloadURL.absoluteString.contains("manifest.googlevideo.com") {
            hlsAsset = AVURLAsset(url: url)
        } else {
            hlsAsset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": "Range: bytes=0-"])
        }
        
        if let thumbnailData = self.state.thumbnailData {
            launchDownload(thumbnailData: thumbnailData)
        } else if let thumbnailData = thumbnailData {
            launchDownload(thumbnailData: thumbnailData)
        } else {
            if let thumbnailURL = video.thumbnails.last?.url ?? URL(string: "https://i.ytimg.com/vi/\(video.videoId)/hqdefault.jpg") {
                getImage(from: thumbnailURL) { (imageData, _, error) in
                    guard let imageData = imageData, error == nil else { print("Could not download image"); DispatchQueue.main.async { self.downloaderState = .failed; }; return }
                    DispatchQueue.main.async {
                        self.state.thumbnailData = imageData
                    }
                    launchDownload(thumbnailData: imageData)
                }
            } else {
                print("No image")
                DispatchQueue.main.async {
                    self.downloaderState = .failed
                    NotificationCenter.default.post(name: Notification.Name("DownloadingChanged"), object: nil)
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
            NotificationCenter.default.post(name: Notification.Name("DownloadingChanged"), object: nil)
        }
    }

    func resumeDownload() {
        DispatchQueue.main.async {
            self.downloadTask?.resume()
            self.downloadTaskState = self.downloadTask!.state
            self.downloaderState = .downloading
            NotificationCenter.default.post(name: Notification.Name("DownloadingChanged"), object: nil)
        }
    }

    func cancelDownload() {
        DispatchQueue.main.async {
            self.downloadTask?.cancel()
            if self.downloadTask != nil {
                self.downloadTaskState = self.downloadTask!.state
            }
            self.downloaderState = .inactive
            NotificationCenter.default.post(name: Notification.Name("DownloadingChanged"), object: nil)
        }
    }

    @objc func updatePercentage() {
        DispatchQueue.main.async {
            self.objectWillChange.send()
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
