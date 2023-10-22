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
    var metadataContainer = MetadataContainer()
    @ObservedObject private var VPM = VideoPlayerModel.shared
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        NotificationCenter.default.addObserver(
            forName: Notification.Name("ApplicationDidEnterBackground"),
            object: nil,
            queue: nil,
            using: { _ in
                print("djamy0")
                controller.player = nil
            })
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name("ApplicationDidEnterActive"),
            object: nil,
            queue: nil,
            using: { _ in
                print("djamy1")
                controller.player = player
            })
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name("StopPlayer"),
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
        
        updateTitle()
        
        updateChannelName()
        
        updateVideoDescription()
        
        updateThumbnailData()
        
        controller.showsPlaybackControls = showControls
        controller.updatesNowPlayingInfoCenter = true
        controller.player = player
        return controller
    }

    private func stopPlayer() {
        controller.player?.replaceCurrentItem(with: nil)
    }

    private func setAndAppendMetdataItem(value: String, type: AVMetadataIdentifier, key: AVMetadataKey? = nil) {
        let metadataItem = AVMutableMetadataItem()
        metadataItem.locale = NSLocale.current
        if let key = key {
            metadataItem.key = key as any NSCopying & NSObjectProtocol
        } else {
            metadataItem.identifier = type
        }
        metadataItem.value = value as NSString
        metadataItem.extendedLanguageTag = "und"
        player.currentItem?.externalMetadata.append(metadataItem)
    }

    private func setAndAppendImageData(imageData: Data) {
        player.imageData = imageData
        let artwork = createArtworkItem(imageData: imageData)
        self.player.currentItem?.externalMetadata.append(artwork)
    }

    private func createArtworkItem(imageData: Data) -> AVMutableMetadataItem {
        let artwork = AVMutableMetadataItem()
        artwork.value = UIImage(data: imageData)!.pngData() as (NSCopying & NSObjectProtocol)?
        artwork.dataType = kCMMetadataBaseDataType_PNG as String
        artwork.identifier = .commonIdentifierArtwork
        artwork.extendedLanguageTag = "und"
        return artwork
    }
    
    private func updateTitle() {
        if metadataContainer.title != (VPM.video?.title ?? VPM.streamingInfos?.title) ?? VPM.moreVideoInfos?.videoTitle {
            
            player.currentItem?.externalMetadata.removeAll(where: {$0.identifier == .commonIdentifierTitle || $0.identifier == .quickTimeMetadataTitle})
            metadataContainer.title = (VPM.video?.title ?? VPM.streamingInfos?.title) ?? VPM.moreVideoInfos?.videoTitle
            
            if let videoTitle = (VPM.video?.title ?? VPM.streamingInfos?.title) ?? VPM.moreVideoInfos?.videoTitle {
                setAndAppendMetdataItem(
                    value: videoTitle,
                    type: .commonIdentifierTitle
                )
                setAndAppendMetdataItem(
                    value: videoTitle,
                    type: .quickTimeMetadataTitle
                )
            }
        }
    }
    
    private func updateChannelName() {
        if metadataContainer.channelName != (VPM.video?.channel?.name ?? VPM.streamingInfos?.channel?.name) ?? VPM.moreVideoInfos?.channel?.name {
            
            player.currentItem?.externalMetadata.removeAll(where: {$0.identifier == .commonIdentifierTitle || $0.identifier == .iTunesMetadataTrackSubTitle})
            metadataContainer.channelName = (VPM.video?.channel?.name ?? VPM.streamingInfos?.channel?.name) ?? VPM.moreVideoInfos?.channel?.name
            
            if let channelName = (VPM.video?.channel?.name ?? VPM.streamingInfos?.channel?.name) ?? VPM.moreVideoInfos?.channel?.name {
                setAndAppendMetdataItem(
                    value: channelName,
                    type: .commonIdentifierArtist
                )
                setAndAppendMetdataItem(
                    value: channelName,
                    type: .iTunesMetadataTrackSubTitle
                )
            }
        }
    }
    
    private func updateVideoDescription() {
        if metadataContainer.videoDescription != VPM.streamingInfos?.videoDescription ?? VPM.moreVideoInfos?.videoDescription?.map({$0.text ?? ""}).joined() {
            
            player.currentItem?.externalMetadata.removeAll(where: {$0.identifier == .commonIdentifierDescription})
            metadataContainer.videoDescription = VPM.streamingInfos?.videoDescription ?? VPM.moreVideoInfos?.videoDescription?.map({$0.text ?? ""}).joined()
            
            if let videoDescription = VPM.streamingInfos?.videoDescription ?? VPM.moreVideoInfos?.videoDescription?.map({$0.text ?? ""}).joined() {
                setAndAppendMetdataItem(
                    value: videoDescription,
                    type: .commonIdentifierDescription,
                    key: .commonKeyDescription
                )
            }
        }
    }
    
    private func updateThumbnailData() {
        if metadataContainer.thumbnailData != VideoPlayerModel.shared.videoThumbnailData {
            
            player.currentItem?.externalMetadata.removeAll(where: {$0.identifier == .commonIdentifierArtwork})
            metadataContainer.thumbnailData = VideoPlayerModel.shared.videoThumbnailData
            
            if let thumbnailData = VideoPlayerModel.shared.videoThumbnailData {
                setAndAppendImageData(imageData: thumbnailData)
            }
        }
    }
    

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}

    class MetadataContainer {
        var title: String?
        var channelName: String?
        var videoDescription: String?
        var thumbnailData: Data?
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
//            forName: Notification.Name("ApplicationDidEnterBackground"),
//            object: nil,
//            queue: nil,
//            using: { [self] _ in
//                self.player = nil
//            })
//
//        NotificationCenter.default.addObserver(
//            forName: Notification.Name("ApplicationDidEnterActive"),
//            object: nil,
//            queue: nil,
//            using: { [self] _ in
//                print("djamy1")
//                self.player = player
//            })
//
//        NotificationCenter.default.addObserver(
//            forName: Notification.Name("StopPlayer"),
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

func stopPlayerFromPlaying() {
    NotificationCenter.default.post(
        name: Notification.Name("StopPlayer"),
        object: nil
    )
}

class CustomAVPlayer: AVPlayer {
    var imageData: Data?
}
