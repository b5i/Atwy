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
import VideoToolbox

protocol HLSDownloaderDelegate {
    func percentageChanged(_ newPercentage: CGFloat, downloader: HLSDownloader)
}

class HLSDownloader: NSObject, ObservableObject, Identifiable {

    var separatedVideoAndAudioDownloader: SeparatedAudioAndVideoDownloader?
    var delegate: HLSDownloaderDelegate? = nil
    var resourceLoader: HLSDownloaderRessourceLoader?
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
    @Published var percentComplete: Double = 0.0 {
        didSet {
            self.delegate?.percentageChanged(percentComplete, downloader: self)
        }
    }
    
    var expectedBytes: (receivedBytes: Int, totalBytes: Int) = (0, 0)
    
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
        guard let downloadTask = self.downloadTask else { return }
        
        guard downloadTask.countOfBytesExpectedToReceive != 0 && downloadTask.countOfBytesExpectedToReceive != NSURLSessionTransferSizeUnknown else { return }
        
        self.expectedBytes = (Int(downloadTask.countOfBytesReceived), Int(downloadTask.countOfBytesExpectedToReceive))
        
        
        let newPercentage = max(Double(downloadTask.countOfBytesReceived / downloadTask.countOfBytesExpectedToReceive), self.percentComplete)
        DispatchQueue.main.async {
            self.percentComplete = newPercentage
        }
    }
    
    func downloadVideo() async {
        guard self.downloaderState != .downloading else { return }
        DispatchQueue.main.async {
            self.downloaderState = .downloading
        }
        
        DispatchQueue.main.async {
            self.downloadInfo.downloadLocation = nil
            self.expectedBytes = (0, 0)
            self.percentComplete = 0.0
            self.downloadInfo.videoDescription = nil
        }
        if let downloadURL = downloadData?.url {
            downloadHLS(downloadURL: downloadURL, defaultLocaleCode: nil)
        } else {
            do {
                YTM.customHeaders[.videoInfos] = HeadersList(
                    url: URL(string: "https://www.youtube.com/youtubei/v1/player")!,
                    method: .POST,
                    headers: [
                        .init(name: "Accept", content: "*/*"),
                        .init(name: "Accept-Encoding", content: "gzip, deflate, br"),
                        .init(name: "Host", content: "www.youtube.com"),
                        .init(name: "User-Agent", content: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.1 Safari/605.1.15"),
                        .init(name: "Accept-Language", content: "\(YTM.selectedLocale);q=0.9"),
                        .init(name: "Origin", content: "https://www.youtube.com/"),
                        .init(name: "Referer", content: "https://www.youtube.com/"),
                        .init(name: "Content-Type", content: "application/json"),
                        .init(name: "X-Origin", content: "https://www.youtube.com")
                    ],
                    addQueryAfterParts: [
                        .init(index: 0, encode: true),
                        .init(index: 1, encode: true)
                    ],
                    httpBody: [
                        "{\"context\":{\"client\":{\"deviceMake\":\"Apple\",\"deviceModel\":\"\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.5 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20230602.01.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"configInfo\":{},\"screenDensityFloat\":2,\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.5\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":120,\"clientScreen\":\"WATCH\",\"mainAppWebInfo\":{\"graftUrl\":\"/watch?v=",
                        "&pp=YAHIAQE%3D\",\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"videoId\":\"",
                        "\",\"params\":\"YAHIAQE%3D\",\"playbackContext\":{\"contentPlaybackContext\":{\"vis\":5,\"splay\":false,\"autoCaptionsDefaultOn\":false,\"autonavState\":\"STATE_NONE\",\"html5Preference\":\"HTML5_PREF_WANTS\",\"signatureTimestamp\":19508,\"autoplay\":true,\"autonav\":true,\"referer\":\"https://www.youtube.com/\",\"lactMilliseconds\":\"-1\",\"watchAmbientModeContext\":{\"hasShownAmbientMode\":true,\"watchAmbientModeEnabled\":true}}},\"racyCheckOk\":false,\"contentCheckOk\":false}"
                    ],
                    parameters: [
                        .init(name: "prettyPrint", content: "false")
                    ]
                )
                
                let firstFetchResult = try await self.downloadInfo.video.fetchStreamingInfosThrowing(youtubeModel: YTM)
                
                YTM.customHeaders[.videoInfos] = nil
                
                if let streamingURL = firstFetchResult.streamingURL {
                    DispatchQueue.main.safeSync {
                        self.downloadInfo.videoDescription = firstFetchResult.videoDescription
                    }
                    
                    let defaultLocaleCode = firstFetchResult.downloadFormats
                        .compactMap { $0 as? VideoInfosWithDownloadFormatsResponse.AudioOnlyFormat }
                        .first(where: { $0.formatLocaleInfos?.isDefaultAudioFormat == true })?.formatLocaleInfos?.localeId
                    if defaultLocaleCode == nil {
                        self.downloadHLS(downloadURL: streamingURL, defaultLocaleCode: nil)
                    } else {
                        let newResponse = try await self.downloadInfo.video.fetchStreamingInfosThrowing(youtubeModel: YTM)
                        
                        let audioDownloadFormat = newResponse.downloadFormats
                            .compactMap { $0 as? VideoInfosWithDownloadFormatsResponse.AudioOnlyFormat }
                            .filter { $0.formatLocaleInfos?.localeId == defaultLocaleCode && $0.mimeType == "audio/mp4" }
                            .max(by: { ($0.averageBitrate ?? 0) < ($1.averageBitrate ?? 0) })
                        let videoDownloadFormat = newResponse.downloadFormats
                            .compactMap { $0 as? VideoInfosWithDownloadFormatsResponse.VideoDownloadFormat }
                            .filter { $0.mimeType == "video/mp4" && $0.codec != "av01" } // AVMutableComposition doesn't support av01 codec for the moment
                            .max(by: { ($0.averageBitrate ?? 0) < ($1.averageBitrate ?? 0) })
                        
                        guard let videoURL = videoDownloadFormat?.url, let audioURL = audioDownloadFormat?.url else {
                            self.downloadHLS(downloadURL: streamingURL, defaultLocaleCode: nil)
                            return
                        }
                            
                        self.downloadSeparatedAudioAndVideo(videoURL: videoURL, audioURL: audioURL)
                    }
                } else {
                    Logger.atwyLogs.simpleLog("Couldn't get video streaming url.")
                    DispatchQueue.main.async {
                        self.downloaderState = .failed
                        NotificationCenter.default.post(name: .atwyDownloadingsChanged, object: nil)
                    }
                }
            } catch {
                Logger.atwyLogs.simpleLog("Couldn't get video streaming data, error: \(error.localizedDescription).")
                DispatchQueue.main.async {
                    self.downloaderState = .failed
                    NotificationCenter.default.post(name: .atwyDownloadingsChanged, object: nil)
                }
            }
        }
    }
    
    private func downloadSeparatedAudioAndVideo(videoURL: URL, audioURL: URL) {
        self.separatedVideoAndAudioDownloader = SeparatedAudioAndVideoDownloader(audioURL: audioURL, videoURL: videoURL, downloadInfo: downloadInfo, downloader: self, endOfDownload: { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let location):
                self.processEndOfDownload(finalURL: location)
            case .failure(let error):
                Logger.atwyLogs.simpleLog("Error downloading separated audio and video: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.downloaderState = .failed
                    NotificationCenter.default.post(name: .atwyDownloadingsChanged, object: nil)
                }
            }
        })
        self.separatedVideoAndAudioDownloader?.start()
    }

    private func downloadHLS(downloadURL: URL, defaultLocaleCode: String?) {
        func launchDownload(isHLS: Bool) {
            Task {
                if #available(iOS 16.1, *) {
                    let activity = DownloaderProgressActivity(downloader: self)
                    activity.setupOnManager(attributes: .init(), state: activity.getNewData())
                }
                
                let infos = try? await self.downloadInfo.video.fetchMoreInfosThrowing(youtubeModel: YTM)
                DispatchQueue.main.safeSync {
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
                    
                    DispatchQueue.main.safeSync {
                        self.downloadInfo.chapters.append(chapterEntity)
                    }
                }
                
                if let channelThumbnailURL = self.downloadInfo.videoInfo?.channel?.thumbnails.maxFor(3) ?? self.downloadInfo.video.channel?.thumbnails.maxFor(3) {
                    let imageTask = DownloadImageOperation(imageURL: channelThumbnailURL.url)
                    imageTask.start()
                    imageTask.waitUntilFinished()
                    DispatchQueue.main.safeSync {
                        self.downloadInfo.channelThumbnailData = imageTask.imageData
                    }
                }
                self.startedEndProcedure = false

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
                    
                    
                    let asset: AVURLAsset
                    
                    if let defaultLocaleCode = defaultLocaleCode {
                        //let components = NSURLComponents.init(url: downloadURL, resolvingAgainstBaseURL: true)
                        //components?.scheme = "customdownloadloader"
                        //asset = AVURLAsset(url: components!.url!)
                        asset = AVURLAsset(url: downloadURL)
                        //self.resourceLoader = HLSDownloaderRessourceLoader(defaultLocaleCode: defaultLocaleCode)
                        //asset.resourceLoader.setDelegate(self.resourceLoader, queue: .main)
                        //asset.resourceLoader.preloadsEligibleContentKeys = true
                        //print(try await asset.load(.allMediaSelections))
                    } else {
                        asset = AVURLAsset(url: downloadURL)
                    }
                    let downloadConfiguration = AVAssetDownloadConfiguration(asset: asset, title: downloadInfo.video.title ?? "No title")
                    downloadConfiguration.artworkData = downloadInfo.thumbnailData
                    
                    let downloadTask = assetDownloadURLSession.makeAssetDownloadTask(downloadConfiguration: downloadConfiguration)
                    downloadTask.resume()
                    self.downloadTask?.cancel()
                    DispatchQueue.main.async {
                        self.downloadTask = downloadTask
                        self.downloadTaskState = downloadTask.state
                    }
                    
                    /*
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
                     */
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
        
        DispatchQueue.main.safeSync {
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
                    DispatchQueue.main.safeSync {
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
            self.separatedVideoAndAudioDownloader?.pause()
            self.downloadTask?.suspend()
            self.downloadTaskState = self.downloadTask?.state ?? .suspended
            self.downloaderState = .paused
            NotificationCenter.default.post(name: .atwyDownloadingsChanged, object: nil)
        }
    }

    func resumeDownload() {
        DispatchQueue.main.async {
            self.separatedVideoAndAudioDownloader?.start()
            self.downloadTask?.resume()
            self.downloadTaskState = self.downloadTask?.state ?? .running
            self.downloaderState = .downloading
            NotificationCenter.default.post(name: .atwyDownloadingsChanged, object: nil)
        }
    }

    func cancelDownload() {
        DispatchQueue.main.async {
            self.separatedVideoAndAudioDownloader?.cancel()
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
    
    // Should never be called directly
    func processEndOfDownload(finalURL: URL) {
        let backgroundContext = PersistenceModel.shared.controller.container.newBackgroundContext()
        backgroundContext.performAndWait {
            let newVideo = DownloadedVideo(context: backgroundContext)
            newVideo.timestamp = Date()
            newVideo.storageLocation = finalURL
            newVideo.title = self.downloadInfo.videoInfo?.videoTitle ?? self.downloadInfo.video.title
            if let imageData = self.downloadInfo.thumbnailData {
                newVideo.thumbnail = self.cropImage(data: imageData)
            }
            newVideo.timeLength = self.downloadInfo.video.timeLength
            newVideo.timePosted = self.downloadInfo.videoInfo?.timePosted.postedDate
            newVideo.videoId = self.downloadInfo.video.videoId
            
            for chapter in self.downloadInfo.chapters {
                newVideo.addToChapters(chapter.getEntity(context: backgroundContext))
            }
            
            if let channelId = self.downloadInfo.video.channel?.channelId {
                let fetchRequest = DownloadedChannel.fetchRequest()
                fetchRequest.fetchLimit = 1
                fetchRequest.predicate = NSPredicate(format: "channelId == %@", channelId)
                let result = try? backgroundContext.fetch(fetchRequest)
                
                if let channel = result?.first {
                    channel.thumbnail = self.downloadInfo.channelThumbnailData
                    channel.addToVideos(newVideo)
                } else {
                    let newChannel = DownloadedChannel(context: backgroundContext)
                    newChannel.channelId = channelId
                    newChannel.name = self.downloadInfo.videoInfo?.channel?.name ?? self.downloadInfo.video.channel?.name
                    newChannel.thumbnail = self.downloadInfo.channelThumbnailData
                    newChannel.addToVideos(newVideo)
                }
            }
            
            newVideo.videoDescription = self.downloadInfo.videoDescription
            do {
                try backgroundContext.save()
                PersistenceModel.shared.currentData.addDownloadedVideo(videoId: self.downloadInfo.video.videoId, storageLocation: finalURL)
                Logger.atwyLogs.simpleLog("Video downloaded successfully, saved to \(finalURL)")
                DispatchQueue.main.async {
                    self.percentComplete = 100
                    self.downloaderState = .success
                    NotificationCenter.default.post(
                        name: .atwyCoreDataChanged,
                        object: nil
                    )
                }
            } catch {
                let nsError = error as NSError
                Logger.atwyLogs.simpleLog("Unresolved error \(nsError), \(nsError.userInfo)")
                DispatchQueue.main.async {
                    self.downloaderState = .failed
                }
            }
        }
    }
    
    @Sendable private func cropImage(data: Data) -> Data? {
        guard let uiImage = UIImage(data: data) else { return nil }
        let portionToCut = (uiImage.size.height - uiImage.size.width * 9/16) / 2
        
        // Scale cropRect to handle images larger than shown-on-screen size
        let cropZone = CGRect(x: 0,
                              y: portionToCut,
                              width: uiImage.size.width,
                              height: uiImage.size.height - portionToCut * 2)
        
        // Perform cropping in Core Graphics
        guard let cutImageRef: CGImage = uiImage.cgImage?.cropping(to: cropZone)
        else {
            return nil
        }
        
        // Return image to UIImage
        let croppedImage: UIImage = UIImage(cgImage: cutImageRef)
        return croppedImage.pngData()
    }
}
