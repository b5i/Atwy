//
//  YTAVPlayerItem.swift
//  Atwy
//
//  Created by Antoine Bollengier on 19.03.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation
import YouTubeKit
import AVKit
import OSLog

class YTAVPlayerItem: AVPlayerItem, ObservableObject {
    var videoId: String { self.video.videoId }
    var videoTitle: String? { self.video.title ?? self.streamingInfos.title ?? self.moreVideoInfos?.videoTitle }
    var channelName: String? { self.video.channel?.name ?? self.streamingInfos.channel?.name ?? self.moreVideoInfos?.channel?.name }
    var videoDescription: String? { self.streamingInfos.videoDescription ?? self.moreVideoInfos?.videoDescription?.map({$0.text ?? ""}).joined() }
    
    let video: YTVideo
    var streamingInfos: VideoInfosResponse
    
    var isFetchingMoreVideoInfos: Bool = false
    
    var isAbleToLike: Bool {
        return NetworkReachabilityModel.shared.connected && self.moreVideoInfos?.authenticatedInfos?.likeStatus != nil
    }
    
    @Published private(set) var moreVideoInfos: MoreVideoInfosResponse? = nil {
        didSet {
            // just modify the chapter's url because they could have some thumbnailData
            if let chapters = self.chapters, self.moreVideoInfos?.chapters?.map({$0.startTimeSeconds}) == chapters.map({$0.time}) {
                for i in 0..<chapters.count {
                    self.chapters?[i].thumbnailURLs = self.moreVideoInfos?.chapters?[i].thumbnail
                }
            } else {
                self.chapters = self.moreVideoInfos?.chapters?.compactMap({ chapter in
                    if let time = chapter.startTimeSeconds {
                        return Chapter(time: time, formattedTime: chapter.timeDescriptions.shortTimeDescription, title: chapter.title, thumbnailURLs: chapter.thumbnail)
                    }
                    return nil
                })
            }
        }
    }
    
    var chapters: [Chapter]?
    var videoThumbnailData: Data? = nil
    var channelAvatarImageData: Data? = nil
    
    init(video: YTVideo, thumbnailData: Data? = nil, channelAvatarImageData: Data? = nil) async throws {
        self.video = video
        
#if !os(macOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        } catch {
            Logger.atwyLogs.simpleLog("Error while trying to load video (audio): \(error)")
        }
#endif

        if let downloadedVideo = PersistenceModel.shared.getDownloadedVideo(videoId: video.videoId) {
            self.streamingInfos = VideoInfosResponse.createEmpty()
            self.streamingInfos.streamingURL = downloadedVideo.storageLocation
            if let channel = downloadedVideo.channel {
                self.streamingInfos.channel = YTLittleChannelInfos(channelId: channel.channelId, name: channel.name)
            }
            self.streamingInfos.title = downloadedVideo.title
            self.streamingInfos.videoDescription = downloadedVideo.videoDescription
            
            self.videoThumbnailData = thumbnailData ?? downloadedVideo.thumbnail
            self.channelAvatarImageData = channelAvatarImageData ?? downloadedVideo.channel?.thumbnail
            self.chapters = downloadedVideo.chaptersArray.map({ .init(time: Int($0.startTimeSeconds), formattedTime: $0.shortTimeDescription, title: $0.title, thumbnailData: $0.thumbnail)
            })
        } else {
            guard NetworkReachabilityModel.shared.connected else { throw "Attempted to load a non-downloaded video while being offline." }
            self.streamingInfos = try await video.fetchStreamingInfosThrowing(youtubeModel: YTM)
        }
        guard let url = self.streamingInfos.streamingURL else { throw "Couldn't get streaming URL." }
        super.init(asset: AVURLAsset(url: url), automaticallyLoadedAssetKeys: nil)
        
        self.addMetadatas()
        if let thumbnailData = self.videoThumbnailData {
            self.setAndAppendImageData(imageData: thumbnailData)
        }
    
        self.fetchMoreInfos()
    }
    
    private func addMetadatas() {
        let metadatas = Self.getMetadatasForInfos(title: self.video.title ?? "", channelName: self.video.channel?.name ?? self.streamingInfos.channel?.name ?? self.moreVideoInfos?.channel?.name ?? "", videoDescription: self.streamingInfos.videoDescription ?? "")
        for metadataItem in metadatas {
            self.setAndAppendMetdataItem(value: metadataItem.value, type: metadataItem.identifier, key: metadataItem.key)
        }
    }
    
    func fetchMoreInfos() {
        guard NetworkReachabilityModel.shared.connected else { return }
        guard self.moreVideoInfos == nil, !self.isFetchingMoreVideoInfos else { return }
        self.isFetchingMoreVideoInfos = true
        
        Task {
            let moreVideoInfosResponse = try await video.fetchMoreInfosThrowing(youtubeModel: YTM)
            DispatchQueue.main.async {
                self.moreVideoInfos = moreVideoInfosResponse
            }
            if let thumbnailURL = self.video.thumbnails.last ?? self.streamingInfos.thumbnails.last {
                let fetchThumbnailOperation = DownloadImageOperation(imageURL: thumbnailURL.url)
                fetchThumbnailOperation.completionBlock = {
                    if let thumbnailData = fetchThumbnailOperation.imageData {
                        self.videoThumbnailData = thumbnailData
                        self.setAndAppendImageData(imageData: thumbnailData)
                    }
                }
                fetchThumbnailOperation.start()
            }
            
            self.addMetadatas()
            self.isFetchingMoreVideoInfos = false
            
            self.update()
        }
    }
    
    func setNewLikeStatus(_ likeStatus: MoreVideoInfosResponse.AuthenticatedData.LikeStatus) {
        DispatchQueue.main.async {
            self.moreVideoInfos?.authenticatedInfos?.likeStatus = likeStatus
        }
    }
    
    func setNewSubscriptionStatus(_ isSubscribed: Bool) {
        DispatchQueue.main.async {
            self.moreVideoInfos?.authenticatedInfos?.subscriptionStatus = isSubscribed
        }
    }
    
    private static func getMetadatasForInfos(title: String, channelName: String, videoDescription: String) -> [(value: String, identifier: AVMetadataIdentifier, key: AVMetadataKey? )] {
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
    
    private func setAndAppendMetdataItem(value: String, type: AVMetadataIdentifier, key: AVMetadataKey? = nil) {
        let metadataItem = AVMutableMetadataItem()
        metadataItem.locale = NSLocale.current
        if let key = key {
            self.externalMetadata.removeAll(where: {$0.key as? AVMetadataKey == key})
            metadataItem.key = key as any NSCopying & NSObjectProtocol
        } else {
            self.externalMetadata.removeAll(where: {$0.identifier == type})
            metadataItem.identifier = type
        }
        metadataItem.value = value as NSString
        metadataItem.extendedLanguageTag = "und"
        self.externalMetadata.append(metadataItem)
    }

    private func setAndAppendImageData(imageData: Data) {
        func createArtworkItem(imageData: Data) -> AVMutableMetadataItem {
            let artwork = AVMutableMetadataItem()
            artwork.value = UIImage(data: imageData)?.pngData() as (NSCopying & NSObjectProtocol)?
            artwork.dataType = kCMMetadataBaseDataType_PNG as String
            artwork.identifier = .commonIdentifierArtwork
            artwork.extendedLanguageTag = "und"
            return artwork
        }
        
        let artwork = createArtworkItem(imageData: imageData)
        self.externalMetadata.removeAll(where: {$0.identifier == .commonIdentifierArtwork})
        self.externalMetadata.append(artwork)
    }
    
    private func update() {
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    public struct Chapter {
        var time: Int
        var formattedTime: String?
        var title: String?
        var thumbnailData: Data?
        var thumbnailURLs: [YTThumbnail]?
    }
}
