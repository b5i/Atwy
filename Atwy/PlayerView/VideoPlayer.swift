//
//  VideoPlayer.swift
//  Atwy
//
//  Created by Antoine Bollengier on 24.11.22.
//  Copyright © 2022-2026 Antoine Bollengier. All rights reserved.
//

import Foundation
import AVKit
import SwiftUI
#if !os(macOS)
import MediaPlayer
#endif

#if canImport(UIKit)
import UIKit
import Combine
import YouTubeKit
import BetterMenus

struct PlayerViewController: UIViewControllerRepresentable {
    var player: CustomAVPlayer
    var showControls: Bool = true
    var controller: AVPlayerViewController
#if !os(macOS)
    var nowPlayingController = MPNowPlayingInfoCenter.default()
#endif
    var audioSession = AVAudioSession.sharedInstance()
    @ObservedObject private var PSM = PreferencesStorageModel.shared
    
    class Model: NSObject, AVPlayerViewControllerDelegate {
        private var isFullScreen: Bool = false
                
        private weak var mainPlayer: AVPlayerViewController?
        
        private var backgroundObserver: NSObjectProtocol? = nil
        
        private var combineObservers: Set<AnyCancellable> = .init()
                        
        init(mainPlayer: AVPlayerViewController) {
            self.mainPlayer = mainPlayer
            super.init()
            self.backgroundObserver = NotificationCenter.default.addObserver(forName:             UIApplication.didEnterBackgroundNotification, object: nil, queue: nil, using: { [weak self] _ in
                if let isFullscreen = self?.mainPlayer?.value(forKey: "avkit_isEffectivelyFullScreen") as? Bool {
                    self?.isFullScreen = isFullscreen
                }
            })
            DeviceOrientationModel.shared.$orientation
                .sink { [weak self] newValue in
                    guard PreferencesStorageModel.shared.automaticFullscreen else { return }
                    switch newValue {
                    case .landscapeLeft, .landscapeRight:
                        self?.setNewFullScreenState(isFullScreen: true)
                    case .portrait:
                        self?.setNewFullScreenState(isFullScreen: false)
                    default:
                        break
                    }
                }
                .store(in: &self.combineObservers)
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self.backgroundObserver as Any)
        }
        
        func setNewFullScreenState(isFullScreen: Bool, fullScreenCompletionBlock: (@convention(block) @escaping () -> ()) = {}) {
            if isFullScreen {
                self.mainPlayer?.perform(NSSelectorFromString("enterFullScreenAnimated:completionHandler:"), with: true, with: fullScreenCompletionBlock)
            } else {
                self.mainPlayer?.perform(NSSelectorFromString("exitFullScreenAnimated:completionHandler:"), with: true, with: fullScreenCompletionBlock)
            }
        }
        
        func playerViewController(_ playerViewController: AVPlayerViewController,
                                  restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
            self.mainPlayer = playerViewController
            SheetsModel.shared.showSheet(.watchVideo)
            let fullScreenEnteringCompletionBlock: (@convention(block) () -> ()) = {
                completionHandler(true)
            }
            self.setNewFullScreenState(isFullScreen: isFullScreen, fullScreenCompletionBlock: fullScreenEnteringCompletionBlock) // restore the fullscreen state
        }
        
        func playerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator coordinator: any UIViewControllerTransitionCoordinator) {
            self.mainPlayer = playerViewController

            self.isFullScreen = true
        }
        
        func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: any UIViewControllerTransitionCoordinator) {
            self.mainPlayer = playerViewController
            
            self.isFullScreen = false
            
            let isPlaying = playerViewController.player?.isPlaying ?? false
            
            coordinator.animate(alongsideTransition: nil, completion: { _ in
                if isPlaying {
                    playerViewController.player?.play()
                }
            })
        }
    }
    
    func makeCoordinator() -> Model {
        return Model(mainPlayer: self.controller)
    }
        
    @BUIMenuBuilder static func makeControls() -> UIMenu {
        Button("Share", image: UIImage(systemName: "plus.circle")) { _ in
            VideoPlayerModel.shared.currentItem?.video.showShareSheet()
        }
        BetterMenus.Divider()
        BetterMenus.Menu("Add to playlist", image: UIImage(systemName: "plus.circle")) {
            Async { () -> (playlists: [(playlist: YTPlaylist, isVideoPresentInside: Bool)], videoId: String) in
                guard let video = VideoPlayerModel.shared.currentItem?.video else { return ([], "") }
                let response = try? await video.fetchAllPossibleHostPlaylistsThrowing(youtubeModel: YTM)
                guard response?.isDisconnected != true else { return ([], "") }
                return (response?.playlistsAndStatus ?? [], video.videoId)
            } body: { playlistInfo in
                ForEach(playlistInfo.playlists) { (playlist, isVideoPresentInside) in
                    Button(playlist.title ?? "Unknown name", image: UIImage(systemName: PrivacyIconView.getIconNameForPrivacyType(playlist.privacy ?? .unlisted))) {_ in
                        if isVideoPresentInside {
                            RemoveVideoByIdFromPlaylistResponse.sendNonThrowingRequest(youtubeModel: YTM, data: [.movingVideoId: playlistInfo.videoId, .browseId: playlist.playlistId], result: {_ in
                                AsyncStorage.modifyCache(forIdentifier: "player-add-to-playlist-\(playlistInfo.videoId)", { (content: (playlists: [(playlist: YTPlaylist, isVideoPresentInside: Bool)], videoId: String)) in
                                    if let playlistContentIndex = content.playlists.firstIndex(where: {$0.playlist.playlistId == playlist.playlistId}) {
                                        var playlists = content.playlists
                                        var playlistElement = playlists[playlistContentIndex]
                                        playlistElement.isVideoPresentInside = false
                                        playlists[playlistContentIndex] = playlistElement
                                        let newContent = (playlists: playlists, videoId: content.videoId)
                                        return newContent
                                    }
                                    return content
                                })
                                PrivateManager.shared.avButtonsManager?.controlsView.refreshMenu(withIdentifier: "Add-To-Playlist-Player", newMenu: makeControls())
                            })
                        } else {
                            AddVideoToPlaylistResponse.sendNonThrowingRequest(youtubeModel: YTM, data: [.movingVideoId: playlistInfo.videoId, .browseId: playlist.playlistId], result: { _ in
                                AsyncStorage.modifyCache(forIdentifier: "player-add-to-playlist-\(playlistInfo.videoId)", { (content: (playlists: [(playlist: YTPlaylist, isVideoPresentInside: Bool)], videoId: String)) in
                                    if let playlistContentIndex = content.playlists.firstIndex(where: {$0.playlist.playlistId == playlist.playlistId}) {
                                        var playlists = content.playlists
                                        var playlistElement = playlists[playlistContentIndex]
                                        playlistElement.isVideoPresentInside = true
                                        playlists[playlistContentIndex] = playlistElement
                                        let newContent = (playlists: playlists, videoId: content.videoId)
                                        return newContent
                                    }
                                    return content
                                })
                                PrivateManager.shared.avButtonsManager?.controlsView.refreshMenu(withIdentifier: "Add-To-Playlist-Player", newMenu: makeControls())
                            })
                        }
                    }
                    .style(.keepsMenuPresented)
                    .state(isVideoPresentInside ? .on : .off)
                }
            }
            .cached(true)
            .identifier("player-add-to-playlist-\(VideoPlayerModel.shared.currentItem?.video.videoId ?? "")")
            .calculateBodyWithCache(true)
        }
        .identifier("Add-To-Playlist-Player")
    }
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        //        NotificationCenter.default.addObserver(
        //            forName: UIApplication.didEnterBackgroundNotification,
        //            object: nil,
        //            queue: nil,
        //            using: { _ in
        //                controller.player = nil
        //            })
        //
        //        NotificationCenter.default.addObserver(
        //            forName: UIApplication.didBecomeActiveNotification,
        //            object: nil,
        //            queue: nil,
        //            using: { _ in
        //                controller.player = player
        //            })
        
        NotificationCenter.default.addObserver(
            forName: .atwyStopPlayer,
            object: nil,
            queue: nil,
            using: { _ in
                stopPlayer()
            })
        
        
        player.allowsExternalPlayback = true
        player.audiovisualBackgroundPlaybackPolicy = PSM.backgroundPlayback ? .continuesIfPossible : .pauses
        player.preventsDisplaySleepDuringVideoPlayback = true
        player.automaticallyWaitsToMinimizeStalling = true
#if !os(macOS)
        controller.allowsVideoFrameAnalysis = true
#endif
        controller.allowsPictureInPicturePlayback =  true
        controller.canStartPictureInPictureAutomaticallyFromInline = PSM.automaticPiP
        controller.exitsFullScreenWhenPlaybackEnds = true
        
        controller.showsPlaybackControls = showControls
        controller.updatesNowPlayingInfoCenter = true
        controller.player = player
        controller.delegate = context.coordinator
        
        PrivateManager.shared.avButtonsManager?.controlsView.menuState = .automatic // initialize it
        
        let controls = [PlayerViewController.makeControls()]
        AsyncStorage.AsyncCacheMaxSize = 1
        controller.perform(NSSelectorFromString("setTransportBarCustomMenuItems:"), with: controls
        )
        /*
        controller.perform(NSSelectorFromString("setTransportBarCustomMenuItems:"), with: [
            UIMenu(title: " ", image: UIImage(systemName: "cube"), options: .displayInline, children: [ // show a divider
                UIDeferredMenuElement({ result in
                    // TODO: make it dynamic in case this changes
                    guard APIKeyModel.shared.userAccount != nil else { result([]); return }
                    
                    result([UIMenu(title: "Add To Playlist", image: UIImage(systemName: "plus.circle"), children: [
                        UIDeferredMenuElement({ result in
                            guard let video = VideoPlayerModel.shared.currentItem?.video else { result([]); return }
                            video.fetchAllPossibleHostPlaylists(youtubeModel: YTM, result: { returning in
                                switch returning {
                                case .success(let response):
                                    guard !response.isDisconnected else { fallthrough }
                                    DispatchQueue.main.async {
                                        result(response.playlistsAndStatus.map({ playlistAndStatus in
                                            return UIAction(
                                                title: playlistAndStatus.playlist.title ?? "Unknown name",
                                                image: UIImage(systemName: PrivacyIconView.getIconNameForPrivacyType(playlistAndStatus.playlist.privacy ?? .unlisted)),
                                                state: playlistAndStatus.isVideoPresentInside ? .on : .off,
                                                handler: { _ in
                                                    if playlistAndStatus.isVideoPresentInside {
                                                        RemoveVideoByIdFromPlaylistResponse.sendNonThrowingRequest(youtubeModel: YTM, data: [.movingVideoId: video.videoId, .browseId: playlistAndStatus.playlist.playlistId], result: {_ in})
                                                    } else {
                                                        AddVideoToPlaylistResponse.sendNonThrowingRequest(youtubeModel: YTM, data: [.movingVideoId: video.videoId, .browseId: playlistAndStatus.playlist.playlistId], result: { _ in })
                                                    }
                                                })
                                        }))
                                    }
                                case .failure(_):
                                    DispatchQueue.main.async {
                                        result([])
                                    }
                                }
                            })
                        })
                    ])])
                }),
                UIAction(title: "Share", image: UIImage(systemName: "square.and.arrow.up"), handler: { _ in
                    VideoPlayerModel.shared.currentItem?.video.showShareSheet()
                })
                                                                 ])
        ])
         */
        return controller
    }

    private func stopPlayer() {
        controller.player?.replaceCurrentItem(with: nil)
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // let is360 = (player.currentItem as? YTAVPlayerItem)?.streamingInfos.downloadFormats.contains(where: { ($0 as? VideoInfosWithDownloadFormatsResponse.VideoDownloadFormat)?.is360 == true }) ?? false
        if DeviceOrientationModel.shared.orientation.isLandscape {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: { // add little delay in case it needs to finish a transition
                context.coordinator.setNewFullScreenState(isFullScreen: true)
            })
        }
    }
}

extension Async {
    func setState(_ state: UIMenuElement.State) -> UIDeferredMenuElement {
        let element = self.uiKitEquivalent
        element.setValue(state, forKey: "state")
        return element
    }
}


#else

struct PlayerViewController: View {
    var player: CustomAVPlayer?
    var infos: TrackInformations?
//    @State private var entireTime: Double = 0.0
//    @State private var currentTime: Double = 0.0 {
//        didSet {
//            self.player?.seek(to: CMTime(seconds: currentTime, preferredTimescale: 1000), toleranceBefore: CMTime(seconds: 1, preferredTimescale: 1000), toleranceAfter: CMTime(seconds: 1, preferredTimescale: 1000))
//        }
//    }
    
    init(player: CustomAVPlayer?, infos: TrackInformations? = nil) {
        self.player = player
        self.infos = infos
//        self.entireTime = self.player?.currentItem?.duration.seconds ?? 0.0
//        self.player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 1000), queue: .main, using: { [self] time in
//            self.currentTime = time.seconds
//        })
//        NotificationCenter.default.addObserver(
//            forName: UIApplication.didEnterBackgroundNotification,
//            object: nil,
//            queue: nil,
//            using: { [self] _ in
//                self.player = nil
//            })
//
//        NotificationCenter.default.addObserver(
//            forName: UIApplication.didBecomeActiveNotification,
//            object: nil,
//            queue: nil,
//            using: { [self] _ in
//                Logger.atwyLogs.simpleLog("djamy1")
//                self.player = player
//            })
//
//        NotificationCenter.default.addObserver(
//            forName: .atwyStopPlayer,
//            object: nil,
//            queue: nil,
//            using: { [self] _ in
//                self.player?.replaceCurrentItem(with: nil)
//            })
    }

    var body: some View {
        ZStack {
            VideoPlayer(player: player)
//            Slider(value: $currentTime, in: 0...entireTime)
        }
    }
}

#endif


class CustomAVPlayer: AVQueuePlayer {
    func updateEndAction() {
        self.actionAtItemEnd = self.items().count < 2 ? .pause : .advance
    }
}

extension UIView {    
    func findAllChildsWithType(_ typeName: String) -> [UIView] {
        var list: [UIView] = []
        for subview in subviews {
            if String(describing: type(of: subview)) == typeName {
                list.append(subview)
            }
            list.append(contentsOf: subview.findAllChildsWithType(typeName))
        }
        return list
    }
    
    func getAllChilds() -> [UIView] {
        var childs: [UIView] = []
        for subview in subviews {
            childs.append(subview)
            childs.append(contentsOf: subview.getAllChilds())
        }
        return childs
    }
}
