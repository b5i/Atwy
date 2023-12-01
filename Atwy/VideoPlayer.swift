//
//  VideoPlayer.swift
//  Atwy
//
//  Created by Antoine Bollengier on 24.11.22.
//

import Foundation
import AVKit
import SwiftUI
#if !os(macOS)
import MediaPlayer
#endif

#if canImport(UIKit)
import UIKit
struct PlayerViewController: UIViewControllerRepresentable {
    var player: CustomAVPlayer
    var showControls: Bool = true
    var controller: AVPlayerViewController
#if !os(macOS)
    var nowPlayingController = MPNowPlayingInfoCenter.default()
#endif
    var audioSession = AVAudioSession.sharedInstance()
    @ObservedObject private var VPM = VideoPlayerModel.shared
    
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
        player.audiovisualBackgroundPlaybackPolicy = .continuesIfPossible
        player.preventsDisplaySleepDuringVideoPlayback = true
        player.automaticallyWaitsToMinimizeStalling = true
#if !os(macOS)
        controller.allowsVideoFrameAnalysis = true
#endif
        controller.allowsPictureInPicturePlayback = true
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        controller.exitsFullScreenWhenPlaybackEnds = true
        
        controller.showsPlaybackControls = showControls
        controller.updatesNowPlayingInfoCenter = true
        controller.player = player
        return controller
    }

    private func stopPlayer() {
        controller.player?.replaceCurrentItem(with: nil)
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
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
//                print("djamy1")
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


class CustomAVPlayer: AVPlayer {
    var imageData: Data?
}
