//
//  VideoPlayerModel.swift
//  Atwy
//
//  Created by Antoine Bollengier on 15.01.23.
//  Copyright © 2023-2025 Antoine Bollengier. All rights reserved.
//

import Foundation
import Combine
import AVKit
#if !os(macOS)
import SwiftUI
#endif
import GroupActivities
import YouTubeKit
import OSLog

class VideoPlayerModel: NSObject, ObservableObject {

    static let shared = VideoPlayerModel()

    let player = CustomAVPlayer(playerItem: nil)
    #if !os(macOS)
    private(set) lazy var controller = AVPlayerViewController() // lazy var to avoid  -[UIViewController init] must be used from main thread only
    #endif
    @Published private(set) var isLoadingVideo: Bool = false
    
    @Published private(set) var currentVideo: YTVideoWithData? = nil
    private var loadingVideoTask: Task<Void, Never>? = nil
    
    @Published var isFetchingAppreciation: Bool = false
    @Published @objc dynamic private(set) var currentItem: YTAVPlayerItem? = nil {
        didSet {
            self.player.updateEndAction()
        }
    }
    
    private var subscriptions = Set<AnyCancellable>()

    // The group session to coordinate playback with.
    private var groupSession: GroupSession<WatchInGroupActivity>? {
        didSet {
            guard let session = groupSession else {
                // Stop playback if a session terminates.
                player.rate = 0
                return
            }
            // Coordinate playback with the active session.
            player.playbackCoordinator.coordinateWithSession(session)
            player.playbackCoordinator.delegate = self
        }
    }

    override init() {
        super.init()
        player.publisher(for: \.currentItem)
            .receive(on: DispatchQueue.main)
            .map {
                $0 as? YTAVPlayerItem
            }
            .assign(to: \.currentItem, on: self)
            .store(in: &subscriptions)
        
        CoordinationManager.shared.$enqueuedVideo
            .sink(receiveValue: { video in
                if let video = video {
                    self.loadVideo(video: video.withData())
                } else {
                    self.deleteCurrentVideo()
                }
            })
            .store(in: &subscriptions)

        // The group session subscriber.
        CoordinationManager.shared.$groupSession
            .receive(on: DispatchQueue.main)
            .assign(to: \.groupSession, on: self)
            .store(in: &subscriptions)

        player.publisher(for: \.timeControlStatus, options: [.initial])
            .receive(on: DispatchQueue.main)
            .sink {
                if [.playing, .waitingToPlayAtSpecifiedRate].contains($0) {
//                    Video is in pause mode
                }
            }
            .store(in: &subscriptions)
#if !os(macOS)
        // Observe audio session interruptions.
        NotificationCenter.default
            .publisher(for: AVAudioSession.interruptionNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in

                // Wrap the notification in helper type that extracts the interruption type and options.
                guard let result = InterruptionResult(notification) else { return }

                // Resume playback, if appropriate.
                if result.type == .ended && result.options == .shouldResume {
                    self?.player.play()
                }
            }.store(in: &subscriptions)
#endif
        }
    
    func setCurrentVideoThumbnailData(_ data: Data, videoId: String) {
        guard self.currentVideo?.video.videoId == videoId else { return }
        DispatchQueue.main.async {
            self.currentVideo?.data.thumbnailData = data
        }
    }
    
    func addVideoToBottomQueue(video: YTVideo) {
        if self.currentItem == nil, !self.isLoadingVideo {
            self.loadVideo(video: video.withData())
        } else {
            Task {
                if let item = try? await YTAVPlayerItem(video: video) {
                    VideoPlayerModel.shared.addItemToBottomQueue(item: item)
                }
            }
        }
    }
    
    func addItemToBottomQueue(item: YTAVPlayerItem) {
        self.player.insert(item, after: self.player.items().last)
        self.player.updateEndAction()
    }
    
    
    func addVideoToTopQueue(video: YTVideo) {
        if self.currentItem == nil, !self.isLoadingVideo {
            self.loadVideo(video: video.withData())
        } else {
            Task {
                if let item = try? await YTAVPlayerItem(video: video) {
                    self.addItemToTopQueue(item: item)
                }
            }
        }
    }
    
    func addItemToTopQueue(item: YTAVPlayerItem) {
        self.player.insert(item, after: nil)
        self.player.updateEndAction()
    }
    
    /// `seekTo`: Variable that will make the player seek to that time (in seconds) as soon as it has loaded the video.
    func loadVideo(video: YTVideoWithData, seekTo: Double? = nil) {
        guard currentVideo?.video.videoId != video.video.videoId, self.currentItem?.videoId != video.video.videoId else { return }
        self.deleteCurrentVideo()
        self.currentVideo = video
        self.isLoadingVideo = true
        self.loadingVideoTask = Task {
            do {
                let newItem = try await YTAVPlayerItem(video: video.video, thumbnailData: video.data.thumbnailData, channelAvatarImageData: video.data.channelAvatarData)
                /*
                let djo = MPRemoteCommandCenter.shared()
            
                djo.likeCommand.addTarget(handler: { _ in
                    print("bergei")
                    return .success
                })
                djo.likeCommand.isEnabled = true
                djo.likeCommand.isActive = true
                
                djo.dislikeCommand.addTarget(handler: { _ in
                    print("fernfowfmw")
                    return .success
                })
                djo.dislikeCommand.isEnabled = true
                djo.dislikeCommand.isActive = true
                */
                /*
                let tmt = MPFeedbackCommand()
                let tmt1 = MPFeedbackCommand()
                tmt.addTarget(handler:  { _ in
                    print(1)
                    return .success
                })
                tmt1.addTarget(handler:  { _ in
                    print(2)
                    return .success
                })
                djo.setValue(tmt, forKey: "_addNowPlayingItemToLibraryCommand")
                djo.setValue(tmt1, forKey: "_addItemToLibraryCommand")
                 */
                /*
                let command = MPRemoteCommand()
                command.addTarget(handler: { _ in
                    print("djo1")
                    return .success
                })
                
                let command2 = MPRem..addTarget(handler: { _ in
                    print("djo2")
                    return .success
                })
                djo.setValue(command, forKey: "addItemToLibraryCommand")
                djo.setValue(command2, forKey: "addNowPlayingItemToLibraryCommand")
                 */
                // Not enabled for the moment
                // https://stackoverflow.com/questions/47953605/avplayer-play-network-video-with-separate-audio-url-without-downloading-the-fi
                //                    if let otherLanguageAudio = streamingInfos.downloadFormats.first(where: { audioFormat in
                //                        guard let audioFormat = audioFormat as? VideoInfosWithDownloadFormatsResponse.AudioOnlyFormat else { return false }
                //                        return (audioFormat.formatLocaleInfos?.isDefaultAudioFormat ?? false) && audioFormat.mimeType == "audio/mp4"
                //                       }),
                //                       let audioStreamingURL = otherLanguageAudio.url,
                //                       let otherLanguageVideo = streamingInfos.downloadFormats.first(where: { videoFormat in
                //                           guard let videoFormat = videoFormat as? VideoInfosWithDownloadFormatsResponse.VideoDownloadFormat else { return false }
                //                           return videoFormat.mimeType == "video/mp4"
                //                       }),
                //                       let videoStreamingURL = otherLanguageVideo.url {
                //                        let videoAsset = AVURLAsset(url: videoStreamingURL, options: ["AVURLAssetHTTPHeaderFieldsKey": ["Range": "bytes=0-"]])
                //                        let audioAsset = AVURLAsset(url: audioStreamingURL, options: ["AVURLAssetHTTPHeaderFieldsKey": ["Range": "bytes=0-"]])
                //                        do {
                //                            guard let contentDurationMilliseconds = otherLanguageAudio.contentDuration ?? otherLanguageVideo.contentDuration, let videoContentLength = otherLanguageVideo.contentLength, let audioContentLength = otherLanguageAudio.contentLength else {
                //                                Logger.atwyLogs.simpleLog("Couldn't get duration or contentLengths.")
                //                                DispatchQueue.main.async {
                //                                    self.player.replaceCurrentItem(with: AVPlayerItem(asset: AVURLAsset(url: streamingURL)))
                //                                }
                //                                NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player.currentItem, queue: nil, using: { _ in
                //                                    NotificationCenter.default.post(name: .atwyAVPlayerEnded, object: nil)
                //                                })
                //                                do {
                //            #if !os(macOS)
                //                                    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
                //            #endif
                //                                } catch {
                //                                    Logger.atwyLogs.simpleLog("Couldn't set playback mode, error: \(error)")
                //                                }
                //
                //                                let potentialDownloader = downloads.last(where: {$0.video?.videoId == VideoPlayerModel.shared.video?.videoId})
                //                                if potentialDownloader != nil {
                //                                    self.downloader = potentialDownloader!
                //                                } else {
                //                                    self.downloader = HLSDownloader()
                //                                }
                //
                //                                self.fetchMoreInfosForVideo()
                //                                DispatchQueue.main.async {
                //                                    self.isLoadingVideo = false
                //                                }
                //                                self.player.play()
                //                                DispatchQueue.main.async {
                //                                    self.objectWillChange.send()
                //                                }
                //                                return
                //                            }
                //
                //                            let contentDuration = CMTime(seconds: Double(contentDurationMilliseconds) / 1000, preferredTimescale: 1).
                //
                //                            let composition = AVMutableComposition()
                //
                //                            let partsSizeBytes: Int = 300_000
                //
                //                            let videoTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
                //                            let totalVideoContent: Int = 0
                //                            while totalVideoContent != videoContentLength {
                //                                let newTotalVideoContent = min(totalVideoContent + partsSizeBytes, videoContentLength)
                //                                let videoAssetPart = AVURLAsset(url: videoStreamingURL.appending(queryItems: [.init(name: "range", value: "\(totalVideoContent)-\(newTotalVideoContent)")]))
                //                                if let firstVideoTrack = try? await videoAssetPart.loadTracks(withMediaType: .video).first {
                //                                    try? videoTrack?.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: contentDuration), of: firstVideoTrack, at: CMTime.zero)
                //                                }
                //                            }
                //
                //                            let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                //                            if let firstAudioTrack = try? await audioAsset.loadTracks(withMediaType: .audio).first {
                //                                try? audioTrack?.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: contentDuration), of: firstAudioTrack, at: CMTime.zero)
                //                            }
                //
                //                            let playerItem = AVPlayerItem(asset: composition)
                //                            DispatchQueue.main.async {
                //                                self.player.replaceCurrentItem(with: playerItem)
                //                            }
                //                        }
                //                    } else {
                
                guard self.currentVideo?.video.videoId == video.video.videoId else { return }
                self.player.replaceCurrentItem(with: newItem)
                await self.player.updateEndAction()
                if let seekTo = seekTo {
                    await self.player.seek(to: CMTime(seconds: seekTo, preferredTimescale: 600))
                }
                self.player.play()
                DispatchQueue.main.async {
                    //self.loadingVideo = nil TODO: check if this has any impact
                    self.isLoadingVideo = false
                    self.objectWillChange.send()
                }
            } catch {
                Logger.atwyLogs.simpleLog("Error while trying to load video: \(error)")
                NotificationCenter.default.post(name: .atwyDismissPlayerSheet, object: nil)
            }
        }
    }

    public func deleteCurrentVideo() {
        self.loadingVideoTask?.cancel()
        self.loadingVideoTask = nil
        self.currentVideo = nil
        self.player.removeAllItems()
        self.isFetchingAppreciation = false
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
}
#if !os(macOS)
struct InterruptionResult {

    let type: AVAudioSession.InterruptionType
    let options: AVAudioSession.InterruptionOptions

    init?(_ notification: Notification) {
        // Determine the interruption type and options.
        guard let type = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? AVAudioSession.InterruptionType,
              let options = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? AVAudioSession.InterruptionOptions else {
                  return nil
              }
        self.type = type
        self.options = options
    }
}
#endif

extension VideoPlayerModel: AVPlayerPlaybackCoordinatorDelegate {
    func playbackCoordinator(_ coordinator: AVPlayerPlaybackCoordinator, identifierFor playerItem: AVPlayerItem) -> String {
        return self.currentItem?.videoId ?? ""
    }
}

class AssetRessourceLoader: NSObject, AVAssetResourceLoaderDelegate {
    var defaultLanguage: String? = nil // TODO: use this to let the user choose the language of the video (provoque a main m3u8 reload, filter the new language and seek to the right time)
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForResponseTo authenticationChallenge: URLAuthenticationChallenge) -> Bool {
        return true
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        let url = loadingRequest.request.url!
        
        let components = NSURLComponents.init(url: url, resolvingAgainstBaseURL: true)
        
        components?.scheme = "https"
        
        var newRequest = URLRequest(url: components!.url!)
        newRequest.httpMethod = loadingRequest.request.httpMethod
        newRequest.httpBody = loadingRequest.request.httpBody
        newRequest.allHTTPHeaderFields = loadingRequest.request.allHTTPHeaderFields
        newRequest.timeoutInterval = loadingRequest.request.timeoutInterval
        let task = URLSession.shared.dataTask(with: newRequest) { (data, response, error) in
            guard error == nil,
                let data = data else {
                loadingRequest.finishLoading(with: error)
                    return
            }
            
            var stringToReturn = String(decoding: data, as: UTF8.self).replacingOccurrences(of: #"#EXT-X-STREAM-INF:BANDWIDTH=[0-9]*,CODECS="vp09.*?\n.*?\n"#, with: "", options: .regularExpression) // we remove the entries that contain a VP9 format that the AVPlayer can't play
            
            //let str = String(decoding: data, as: UTF8.self).replacingOccurrences(of: #"YT-EXT-AUDIO-CONTENT-ID=\"([a-zA-Z-]*)[\w\.]*\""#, with: "LANGUAGE=\"$1\",NAME=\"$1\"", options: .regularExpression).data(using: .utf8)!
            
            
            if let defaultLanguage = self.defaultLanguage {
                if stringToReturn.contains("YT-EXT-AUDIO-CONTENT-ID=\"\(defaultLanguage)") {
                    var newString: String = ""
                    var didFindPartToRemove: Bool = false
                    
                    for part in stringToReturn.split(separator: "\n") {
                        guard !didFindPartToRemove else {
                            didFindPartToRemove = false
                            continue
                        }
                        
                        if part.contains("YT-EXT-AUDIO-CONTENT-ID=") && !part.contains("YT-EXT-AUDIO-CONTENT-ID=\"\(defaultLanguage)") {
                            didFindPartToRemove = true
                            continue
                        }
                        
                        newString += part + "\n"
                    }
                    stringToReturn = newString
                } // we remove all the formats that don't have the default language if it's present
            }
            
            loadingRequest.dataRequest?.respond(with: stringToReturn.data(using: .utf8)!)
            
            
            loadingRequest.finishLoading()
        }
        task.resume()
        return true
    }
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForRenewalOfRequestedResource renewalRequest: AVAssetResourceRenewalRequest) -> Bool {
        return true
    }
}
