//
//  VideoPlayerModel.swift
//  Atwy
//
//  Created by Antoine Bollengier on 15.01.23.
//

import Foundation
import Combine
import AVKit
#if !os(macOS)
import MediaPlayer
import SwiftUI
#endif
import GroupActivities
import CoreData
import YouTubeKit

struct WatchInGroupActivity: GroupActivity {
    static var activityIdentifier = "Antoine-Bollengier.Atwy.shareplay"
    var metadata: GroupActivityMetadata {
        var metadata = GroupActivityMetadata()
        metadata.type = .watchTogether
        metadata.title = video.title
        return metadata
    }

    var video: YTVideo
}

struct WatchInGroupActivityMetadata: Codable, Equatable {
    var videoId: String
    var title: String
    var owner: String
    var description: String
    var thumbnailURL: [String]?
}

class CoordinationManager {
    static let shared = CoordinationManager()

    private var subscriptions = Set<AnyCancellable>()

    // Published values that the player, and other UI items, observe.
    @Published var enqueuedVideo: YTVideo?
    @Published var groupSession: GroupSession<WatchInGroupActivity>?

    private init() {
        Task {
            // Await new sessions to watch movies together.
            for await groupSession in WatchInGroupActivity.sessions() {
                print("Got a group session")
                // Set the app's active group session.
                self.groupSession = groupSession

                // Remove previous subscriptions.
                subscriptions.removeAll()

                // Observe changes to the session state.
                groupSession.$state.sink { [weak self] state in
                    if case .invalidated = state {
                        // Set the groupSession to nil to publish
                        // the invalidated session state.
                        self?.groupSession = nil
                        self?.subscriptions.removeAll()
                    }
                }.store(in: &subscriptions)

                // Join the session to participate in playback coordination.
                groupSession.join()

                // Observe when the local user or a remote participant starts an activity.
                groupSession.$activity.sink { [weak self] activity in
                    // Set the movie to enqueue it in the player.
                    self?.enqueuedVideo = activity.video
                }.store(in: &subscriptions)
            }
        }
    }

    // Prepares the app to play the movie.
    func prepareToPlay(_ selectedVideo: YTVideo) {
        // Return early if the app enqueues the movie.
        guard enqueuedVideo != selectedVideo else { return }

        if let groupSession = groupSession {
            // If there's an active session, create an activity for the new selection.
            if groupSession.activity.video != selectedVideo {
                groupSession.activity = WatchInGroupActivity(video: selectedVideo)
            }
        } else {

            Task {
                // Create a new activity for the selected movie.
                let activity = WatchInGroupActivity(video: selectedVideo)

                // Await the result of the preparation call.
                switch await activity.prepareForActivation() {

                case .activationDisabled:
                    // Playback coordination isn't active, or the user prefers to play the
                    // movie apart from the group. Enqueue the movie for local playback only.
                    self.enqueuedVideo = selectedVideo

                case .activationPreferred:
                    // The user prefers to share this activity with the group.
                    // The app enqueues the movie for playback when the activity starts.
                    do {
                        _ = try await activity.activate()
                    } catch {
                        print("Unable to activate the activity: \(error)")
                    }

                case .cancelled:
                    // The user cancels the operation. Do nothing.
                    break

                default: ()
                }
            }
        }
    }
}

class VideoPlayerModel: NSObject, ObservableObject {

    static let shared = VideoPlayerModel()

    @Published var video: YTVideo?
    @Published var player: CustomAVPlayer = CustomAVPlayer(playerItem: nil)
    #if !os(macOS)
    // TODO: implement AVNavigationMarkersGroup
    lazy var controller = AVPlayerViewController()
    var nowPlayingSession: MPNowPlayingSession?
    #endif
    var downloader = HLSDownloader()
    @Published var streamingInfos: VideoInfosResponse?
    @Published var videoThumbnailData: Data? {
        didSet {
            if let videoThumbnailData = videoThumbnailData {
                player.currentItem?.externalMetadata.removeAll(where: {$0.identifier == .commonIdentifierArtwork})
                player.currentItem?.setAndAppendImageData(imageData: videoThumbnailData)
            }
        }
    }
    @Published var channelAvatarData: Data?
    @Published var isLoadingVideo: Bool = false
    
    @Published var isFetchingAppreciation: Bool = false
    
    /// Contains the videoId of the fetch request, nil if it isn't fetching.
    var isFetchingMoreVideoInfos: String?
    

    @Published var moreVideoInfos: MoreVideoInfosResponse?
    @Published var videoDescription: String?
    @Published var chapters: [Chapter]?
//    @StateObject var DM = downloadingsModel

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
        CoordinationManager.shared.$enqueuedVideo
            .receive(on: DispatchQueue.main)
            .compactMap { item in
                if let video = item {
                    self.loadVideo(video: video)
                }
                return item
            }
            .assign(to: \.video, on: self)
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
    
    /// `seekTo`: Variable that will make the player seek to that time (in seconds) as soon as it has loaded the video.
    func loadVideo(video: YTVideo, thumbnailData: Data? = nil, channelAvatarImageData: Data? = nil, seekTo: Double? = nil) {
        guard !isLoadingVideo else { return }
        self.deleteCurrentVideo()
        self.isLoadingVideo = true
        self.video = video
        if let downloadedVideo = PersistenceModel.shared.getDownloadedVideo(videoId: video.videoId) {
            let newPlayingItem = AVPlayerItem(
                asset: .init(url: downloadedVideo.storageLocation),
                metadatas: getMetadatasForInfos(title: downloadedVideo.title ?? video.title ?? "", channelName: downloadedVideo.channel?.name ?? video.channel?.name ?? "", videoDescription: downloadedVideo.videoDescription ?? ""),
                thumbnailData: thumbnailData ?? downloadedVideo.thumbnail)
            DispatchQueue.main.async {
                self.player.replaceCurrentItem(with: newPlayingItem)
                if let seekTo = seekTo {
                    self.player.seek(to: CMTime(seconds: seekTo, preferredTimescale: 600))
                }
            }
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: newPlayingItem, queue: nil, using: { _ in
                NotificationCenter.default.post(name: .atwyAVPlayerEnded, object: nil)
            })
            self.chapters = downloadedVideo.chaptersArray.map({ Chapter(time: Int($0.startTimeSeconds), formattedTime: $0.shortTimeDescription, title: $0.title, thumbnailData: $0.thumbnail) })
            if self.chapters?.isEmpty ?? true {
                self.chapters = nil
            }
            self.streamingInfos = VideoInfosResponse.createEmpty()
            self.streamingInfos?.streamingURL = downloadedVideo.storageLocation
            if let channel = downloadedVideo.channel {
                self.streamingInfos?.channel = YTLittleChannelInfos(channelId: channel.channelId, name: channel.name)
                self.channelAvatarData = channelAvatarImageData ?? channel.thumbnail
            }
            self.streamingInfos?.title = downloadedVideo.title
            self.streamingInfos?.videoDescription = downloadedVideo.videoDescription
            self.videoThumbnailData = thumbnailData ?? downloadedVideo.thumbnail
            if NetworkReachabilityModel.shared.connected {
                self.fetchMoreInfosForVideo()
            }
            do {
#if !os(macOS)
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
#endif
            } catch {
                print("Couldn't set playback mode, error: \(error)")
            }
            
            self.isLoadingVideo = false
            self.player.play()
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        } else {
            DispatchQueue.main.async {
                self.videoThumbnailData = thumbnailData
                self.channelAvatarData = channelAvatarImageData
            }
            Task {
                do {
                    let streamingInfos = try await video.fetchStreamingInfos(youtubeModel: YTM)
                    guard self.video?.videoId == video.videoId else { return }
                    guard let streamingURL = streamingInfos.streamingURL else { print("Couldn't get streamingURL"); return }
                    DispatchQueue.main.async {
                        self.streamingInfos = streamingInfos
                    }
                    if let thumbnailURL = streamingInfos.thumbnails.last?.url {
                        Task {
                            let thumbnailData = await getImage(from: thumbnailURL)
                            if self.video?.videoId == streamingInfos.videoId {
                                DispatchQueue.main.async {
                                    self.videoThumbnailData = thumbnailData
                                }
                            }
                        }
                    }
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
                    //                                print("Couldn't get duration or contentLengths.")
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
                    //                                    print("Couldn't set playback mode, error: \(error)")
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
                    //                            let contentDuration = CMTime(seconds: Double(contentDurationMilliseconds) / 1000, preferredTimescale: 1)
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
                    let newPlayingItem = AVPlayerItem(
                        asset: AVURLAsset(url: streamingURL),
                        metadatas: getMetadatasForInfos(title: streamingInfos.title ?? "", channelName: streamingInfos.channel?.name ?? "", videoDescription: streamingInfos.videoDescription ?? ""),
                        thumbnailData: self.videoThumbnailData)
                    DispatchQueue.main.async {
                        self.player.replaceCurrentItem(with: newPlayingItem)
                        if let seekTo = seekTo {
                            self.player.seek(to: CMTime(seconds: seekTo, preferredTimescale: 600))
                        }
                    }
                    //                    }
                    NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player.currentItem, queue: nil, using: { _ in
                        NotificationCenter.default.post(name: .atwyAVPlayerEnded, object: nil)
                    })
#if !os(macOS)
                    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
#endif
                    
                    let potentialDownloader = downloads.last(where: {$0.video?.videoId == VideoPlayerModel.shared.video?.videoId})
                    if let potentialDownloader = potentialDownloader {
                        self.downloader = potentialDownloader
                    } else {
                        self.downloader = HLSDownloader()
                    }
                    
                    self.fetchMoreInfosForVideo()
                    self.player.play()
                    DispatchQueue.main.async {
                        self.objectWillChange.send()
                    }
                    DispatchQueue.main.async {
                        self.isLoadingVideo = false
                    }
                } catch {
                    print("Error while trying to load video: \(error)")
                }
            }
        }
    }

    public func deleteCurrentVideo() {
        self.isLoadingVideo = false
        self.video = nil
        self.player.replaceCurrentItem(with: nil)
        self.streamingInfos = nil
        self.isFetchingMoreVideoInfos = nil
        self.isFetchingAppreciation = false
        self.moreVideoInfos = nil
        self.channelAvatarData = nil
        self.videoThumbnailData = nil
        self.videoDescription = nil
        self.chapters = nil
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    private func getMetadatasForInfos(title: String, channelName: String, videoDescription: String) -> [(value: String, identifier: AVMetadataIdentifier, key: AVMetadataKey? )] {
        return [
            (title, .commonIdentifierTitle, nil),
            (title, .quickTimeMetadataTitle, nil),
            (channelName, .commonIdentifierArtist, nil),
            (channelName, .iTunesMetadataTrackSubTitle, nil),
            (channelName, .iTunesMetadataArtist, nil),
            (channelName, .quickTimeMetadataArtist, nil),
            (videoDescription, .commonIdentifierDescription, key: .commonKeyDescription),
            (videoDescription, .iTunesMetadataDescription, nil),
            (videoDescription, .quickTimeMetadataDescription, nil)]
    }
    
    public func fetchMoreInfosForVideo() {
        self.isFetchingMoreVideoInfos = self.video?.videoId
        let operationVideoId = self.video?.videoId
        self.video?.fetchMoreInfos(youtubeModel: YTM, result: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                guard self.isFetchingMoreVideoInfos == self.video?.videoId, self.isFetchingMoreVideoInfos == operationVideoId else { return }
                self.isFetchingMoreVideoInfos = nil
                DispatchQueue.main.async {
                    withAnimation {
                        self.moreVideoInfos = response
                    }
                    if self.chapters == nil {
                        withAnimation {
                            self.chapters = response.chapters?.compactMap({ chapter in
                                if let time = chapter.startTimeSeconds {
                                    return Chapter(time: time, formattedTime: chapter.timeDescriptions.shortTimeDescription, title: chapter.title, thumbnailURLs: chapter.thumbnail)
                                }
                                return nil
                            })
                        }
                    }
                }
            case .failure(let error):
                print("Error while fetching more video infos: \(String(describing: error)).")
            }
        })
    }
    
    public struct Chapter {
        var time: Int
        var formattedTime: String?
        var title: String?
        var thumbnailData: Data?
        var thumbnailURLs: [YTThumbnail]?
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
        return self.video?.videoId ?? ""
    }
}

extension AVPlayerItem {
    convenience init(asset: AVAsset, metadatas: [(value: String, identifier: AVMetadataIdentifier, key: AVMetadataKey? )] = [], thumbnailData: Data?) {
        self.init(asset: asset)
        for metadataItem in metadatas {
            self.setAndAppendMetdataItem(value: metadataItem.value, type: metadataItem.identifier, key: metadataItem.key)
        }
        if let thumbnailData = thumbnailData {
            self.setAndAppendImageData(imageData: thumbnailData)
        }
    }
    
    func setAndAppendMetdataItem(value: String, type: AVMetadataIdentifier, key: AVMetadataKey? = nil) {
        let metadataItem = AVMutableMetadataItem()
        metadataItem.locale = NSLocale.current
        if let key = key {
            metadataItem.key = key as any NSCopying & NSObjectProtocol
        } else {
            metadataItem.identifier = type
        }
        metadataItem.value = value as NSString
        metadataItem.extendedLanguageTag = "und"
        self.externalMetadata.append(metadataItem)
    }

    func setAndAppendImageData(imageData: Data) {
        func createArtworkItem(imageData: Data) -> AVMutableMetadataItem {
            let artwork = AVMutableMetadataItem()
            artwork.value = UIImage(data: imageData)?.pngData() as (NSCopying & NSObjectProtocol)?
            artwork.dataType = kCMMetadataBaseDataType_PNG as String
            artwork.identifier = .commonIdentifierArtwork
            artwork.extendedLanguageTag = "und"
            return artwork
        }
        
        let artwork = createArtworkItem(imageData: imageData)
        self.externalMetadata.append(artwork)
    }
}
