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
    private let ressourceLoader = AssetRessourceLoader()
    
    var videoId: String { self.video.videoId }
    var videoTitle: String? { self.video.title ?? self.streamingInfos.title ?? self.moreVideoInfos?.videoTitle }
    var channelName: String? { self.video.channel?.name ?? self.streamingInfos.channel?.name ?? self.moreVideoInfos?.channel?.name }
    var videoDescription: String? { self.streamingInfos.videoDescription ?? self.moreVideoInfos?.videoDescription?.map({$0.text ?? ""}).joined() }
    
    let video: YTVideo
    var streamingInfos: VideoInfosResponse
    
    @Published private(set) var isFetchingMoreVideoInfos: Bool = false
    @Published var isFetchingMoreRecommendedVideos: Bool = false
    
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
    
    @Published private(set) var comments: VideoCommentsResponse? = nil
    @Published private(set) var isFetchingComments: Bool = false
    
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
        
        let isDownloaded: Bool

        if let downloadedVideo = PersistenceModel.shared.getDownloadedVideo(videoId: video.videoId) {
            isDownloaded = true
            
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
            isDownloaded = false
            
            guard NetworkReachabilityModel.shared.connected else { throw "Attempted to load a non-downloaded video while being offline." }
            self.streamingInfos = try await video.fetchStreamingInfosThrowing(youtubeModel: YTM)
        }
        guard let url = self.streamingInfos.streamingURL else { throw "Couldn't get streaming URL." }

        let asset: AVURLAsset
        
        /*
        if !isDownloaded {
            let components = NSURLComponents.init(url: url, resolvingAgainstBaseURL: true)
            components?.scheme = "customloader"
            asset = AVURLAsset(url: components!.url!)
            asset.resourceLoader.setDelegate(ressourceLoader, queue: .main)
        } else {
            asset = AVURLAsset(url: url)
        }
         */
        
        asset = AVURLAsset(url: url)
        
        super.init(asset: asset, automaticallyLoadedAssetKeys: nil)
        
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
        DispatchQueue.main.safeSync {
            self.isFetchingMoreVideoInfos = true
        }
        
        Task.detached { [weak self] in
            guard let self = self else { return }
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
            
            DispatchQueue.main.async {
                self.addMetadatas()
                self.isFetchingMoreVideoInfos = false
                
                self.update()
            }
        }
    }
    
    func fetchMoreRecommendedVideos() {
        guard !self.isFetchingMoreRecommendedVideos else { return }
        
        DispatchQueue.main.async {
            self.isFetchingMoreRecommendedVideos = true
        }
        
        self.moreVideoInfos?.getRecommendedVideosContination(youtubeModel: YTM, result: { result in
            switch result {
            case .success(let response):
                DispatchQueue.main.async {
                    self.moreVideoInfos?.mergeRecommendedVideosContination(response)
                }
            case .failure(_):
                Logger.atwyLogs.simpleLog("Couldn't fetch continuation of recommended videos.")
            }
            DispatchQueue.main.async {
                self.isFetchingMoreRecommendedVideos = false
            }
        })
    }
    
    func fetchVideoComments() {
        guard !self.isFetchingComments, let commentsToken = self.moreVideoInfos?.commentsContinuationToken else { return }
        
        DispatchQueue.main.safeSync {
            self.isFetchingComments = true
        }
        
        Task {
            do {
                let comments = try await VideoCommentsResponse.sendThrowingRequest(youtubeModel: YTM, data: [.continuation: commentsToken])
                
                DispatchQueue.main.safeSync {
                    self.comments = comments
                }
            } catch {
                Logger.atwyLogs.simpleLog("Couldn't fetch comments: \(error.localizedDescription)")
            }
            
            DispatchQueue.main.safeSync {
                self.isFetchingComments = false
            }
        }
    }
    
    func fetchVideoCommentsContinuation() {
        guard !self.isFetchingComments, let comments  = self.comments else { return }
        
        DispatchQueue.main.safeSync {
            self.isFetchingComments = true
        }
        
        Task {
            do {
                let continuation = try await comments.fetchContinuationThrowing(youtubeModel: YTM)
                
                DispatchQueue.main.safeSync {
                    self.comments?.mergeContinuation(continuation)
                }
            } catch {
                Logger.atwyLogs.simpleLog("Couldn't fetch continuation of comments: \(error.localizedDescription)")
            }
            
            DispatchQueue.main.safeSync {
                self.isFetchingComments = false
            }
        }
    }
    
    func commentLikeAction(_ action: YTComment.CommentAction, comment: YTComment) {
        Task {
            do {
                switch action {
                case .like:
                    if comment.likeState != .liked {
                        try await comment.commentAction(youtubeModel: YTM, action: .like)
                        self.changeLikeStatusWithId(comment.commentIdentifier, newStatus: .liked)
                    }
                case .dislike:
                    if comment.likeState != .disliked {
                        try await comment.commentAction(youtubeModel: YTM, action: .dislike)
                        self.changeLikeStatusWithId(comment.commentIdentifier, newStatus: .disliked)
                    }
                case .removeLike:
                    if comment.likeState == .liked {
                        try await comment.commentAction(youtubeModel: YTM, action: .removeLike)
                        self.changeLikeStatusWithId(comment.commentIdentifier, newStatus: .nothing)
                    }
                case .removeDislike:
                    if comment.likeState == .disliked {
                        try await comment.commentAction(youtubeModel: YTM, action: .removeDislike)
                        self.changeLikeStatusWithId(comment.commentIdentifier, newStatus: .nothing)
                    }
                default:
                    return
                }
            } catch {}
        }
    }
    
    func mergeRepliesToComment(_ commentId: String, replies: [YTComment], newToken: String?) {        
        guard let commentIndex = self.getCommentIndex(forId: commentId) else { return }
        
        if let replyIndex = commentIndex.replyIndex {
            self.comments?.results[commentIndex.commentIndex].replies[replyIndex].replies.append(contentsOf: replies)
            self.comments?.results[commentIndex.commentIndex].replies[replyIndex].actionsParams[.repliesContinuation] = newToken
            return
        } else {
            self.comments?.results[commentIndex.commentIndex].replies.append(contentsOf: replies)
            self.comments?.results[commentIndex.commentIndex].actionsParams[.repliesContinuation] = newToken
        }
    }
    
    struct CommentPosition {
        var commentIndex: Int
        var replyIndex: Int?
    }
        
    func getCommentIndex(forId commentId: String) -> CommentPosition? {
        guard let comments = self.comments else { return nil }
        for (index, comment) in comments.results.enumerated() {
            if comment.commentIdentifier == commentId {
                return CommentPosition(commentIndex: index, replyIndex: nil)
            }
            
            if let commentPosition = comment.replies.firstIndex(where: {$0.commentIdentifier == commentId}) {
                return CommentPosition(commentIndex: index, replyIndex: commentPosition)
            }
        }
        
        return nil
    }
    
    func changeLikeStatusAtPosition(_ position: CommentPosition, newStatus: YTLikeStatus) {
        guard self.comments != nil else { return }
        
        guard self.comments?.results.count ?? 0 > position.commentIndex else { return }
        
        if let replyIndex = position.replyIndex {
            guard self.comments?.results[position.commentIndex].replies.count ?? 0 > replyIndex else { return }
            self.comments?.results[position.commentIndex].replies[replyIndex].likeState = newStatus
        } else {
            self.comments?.results[position.commentIndex].likeState = newStatus
        }
    }
    
    func changeLikeStatusWithId(_ commentId: String, newStatus: YTLikeStatus) {
        DispatchQueue.main.async {
            guard let position = self.getCommentIndex(forId: commentId) else { return }
            self.changeLikeStatusAtPosition(position, newStatus: newStatus)
        }
    }
    
    func setNewLikeStatus(_ likeStatus: YTLikeStatus) {
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
