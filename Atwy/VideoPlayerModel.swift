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
    var controller = AVPlayerViewController()
    var nowPlayingSession: MPNowPlayingSession?
    #endif
    var downloader = HLSDownloader()
    @Published var streamingInfos: VideoInfosResponse?
    @Published var videoThumbnailData: Data?
    @Published var channelAvatarData: Data?
    @Published var isLoadingVideo: Bool = false
    @Published var isFetchingAppreciation: Bool = false
    @Published var moreVideoInfos: MoreVideoInfosResponse?
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
    
    func loadVideo(video: YTVideo) {
        guard !isLoadingVideo else { return }
        self.deleteCurrentVideo()
        self.isLoadingVideo = true
        self.video = video
        if let downloadedVideo = checkIfDownloaded(videoId: video.videoId) {
            DispatchQueue.main.async {
                self.player.replaceCurrentItem(with: AVPlayerItem(url: downloadedVideo.storageLocation))
            }
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player.currentItem, queue: nil, using: { _ in
                NotificationCenter.default.post(name: Notification.Name("AVPlayerEnded"), object: nil)
            })
            var streamingInfos = VideoInfosResponse.createEmpty()
            streamingInfos.streamingURL = downloadedVideo.storageLocation
            if let channel = downloadedVideo.channel {
                streamingInfos.channel = YTLittleChannelInfos(channelId: channel.channelId, name: channel.name)
                self.channelAvatarData = channel.thumbnail
            }
            streamingInfos.title = downloadedVideo.title
            self.videoThumbnailData = downloadedVideo.thumbnail
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
            Task {
                let (streamingInfos, error) = await video.fetchStreamingInfosWithDownloadFormats(youtubeModel: YTM)
                if let streamingInfos = streamingInfos, let streamingURL = streamingInfos.videoInfos.streamingURL {
                    DispatchQueue.main.async {
                        self.streamingInfos = streamingInfos.videoInfos
                    }
                    if let thumbnailURL = streamingInfos.videoInfos.thumbnails.last?.url {
                        Task {
                            let thumbnailData = await getImage(from: thumbnailURL)
                            DispatchQueue.main.async {
                                self.videoThumbnailData = thumbnailData
                            }
                        }
                    }
                    // Not enabled for the moment
                    // https://stackoverflow.com/questions/47953605/avplayer-play-network-video-with-separate-audio-url-without-downloading-the-fi
//                    if let otherLanguageAudio = streamingInfos.downloadFormats.first(where: {($0 as? VideoInfosWithDownloadFormatsResponse.AudioOnlyFormat)?.formatLocaleInfos?.isDefaultAudioFormat ?? false}), let audioStreamingURL = otherLanguageAudio.url, let otherLanguageVideo = streamingInfos.downloadFormats.first(where: {($0 as? VideoInfosWithDownloadFormatsResponse.VideoDownloadFormat != nil)}), let videoStreamingURL = otherLanguageVideo.url {
//                        //                        let videoAsset = AVURLAsset(url: videoStreamingURL)
//                        let videoAsset = AVURLAsset(url: videoStreamingURL, options: ["AVURLAssetHTTPHeaderFieldsKey": ["Range": "bytes=0-"]])
//                        let audioAsset = AVURLAsset(url: audioStreamingURL, options: ["AVURLAssetHTTPHeaderFieldsKey": ["Range": "bytes=0-"]])
//                        //                        let audioAsset = AVURLAsset(url: audioStreamingURL)
//                        do {
//                            
//                            var duration = min((try? await videoAsset.load(.duration)) ?? .init(), (try? await audioAsset.load(.duration)) ?? .init())
//                            
//                            let composition = AVMutableComposition()
//                            
//                            let videoTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
//                            if let firstVideoTrack = try? await videoAsset.loadTracks(withMediaType: .video).first {
//                                try? videoTrack?.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: duration), of: firstVideoTrack, at: CMTime.zero)
//                            }
//                            
//                            let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
//                            if let firstAudioTrack = try? await audioAsset.loadTracks(withMediaType: .audio).first {
//                                try? audioTrack?.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: duration), of: firstAudioTrack, at: CMTime.zero)
//                            }
//                            
//                            
//                            let playerItem = AVPlayerItem(asset: composition)
//                            DispatchQueue.main.async {
//                                self.player.replaceCurrentItem(with: playerItem)
//                            }
//                        }
//                    } else {
                        DispatchQueue.main.async {
                            self.player.replaceCurrentItem(with: AVPlayerItem(asset: AVURLAsset(url: streamingURL)))
                        }
//                    }
                    NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player.currentItem, queue: nil, using: { _ in
                        NotificationCenter.default.post(name: Notification.Name("AVPlayerEnded"), object: nil)
                    })
                    do {
#if !os(macOS)
                        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
#endif
                    } catch {
                        print("Couldn't set playback mode, error: \(error)")
                    }
                    
                    let potentialDownloader = downloads.last(where: {$0.video?.videoId == VideoPlayerModel.shared.video?.videoId})
                    if potentialDownloader != nil {
                        self.downloader = potentialDownloader!
                    } else {
                        self.downloader = HLSDownloader()
                    }
                    
                    self.fetchMoreInfosForVideo()
                    DispatchQueue.main.async {
                        self.isLoadingVideo = false
                    }
                    self.player.play()
                    DispatchQueue.main.async {
                        self.objectWillChange.send()
                    }
                } else {
                    print("Error while fetching streaming infos for a video, error: \(String(describing: error)).")
                }
            }
        }
    }

    public func deleteCurrentVideo() {
        self.video = nil
        self.player.replaceCurrentItem(with: nil)
        self.streamingInfos = nil
        self.isFetchingAppreciation = false
        self.moreVideoInfos = nil
        self.channelAvatarData = nil
        self.videoThumbnailData = nil
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }

    private func checkIfDownloaded(videoId: String) -> DownloadedVideo? {
        let fetchRequest = DownloadedVideo.fetchRequest()
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "videoId == %@", videoId)
        let result = try? PersistenceModel.shared.context.fetch(fetchRequest)
        return result?.first
    }
    
    public func fetchMoreInfosForVideo() {
        self.video?.fetchMoreInfos(youtubeModel: YTM, result: { response, error in
            DispatchQueue.main.async {
                self.moreVideoInfos = response
            }
            if let error = error {
                print("Error while fetching more video infos: \(String(describing: error)).")
            }
        })
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
