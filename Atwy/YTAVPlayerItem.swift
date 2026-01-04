//
//  YTAVPlayerItem.swift
//  Atwy
//
//  Created by Antoine Bollengier on 19.03.2024.
//  Copyright © 2024-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
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
    var videoDescription: String? { self.streamingInfos.videoDescription ?? self.moreVideoInfos?.videoDescription?.compactMap(\.text).joined() }
    
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
            if let chapters = self.chapters, self.moreVideoInfos?.chapters?.map(\.startTimeSeconds) == chapters.map(\.time) {
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
    
    @Published var chapters: [Chapter]?
    var videoThumbnailData: Data? = nil
    @Published var channelAvatarImageData: Data? = nil
    
    init(video: YTVideo, thumbnailData: Data? = nil, channelAvatarImageData: Data? = nil) async throws {
        self.video = video
        
#if !os(macOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        } catch {
            Logger.atwyLogs.simpleLog("Error while trying to load video (audio): \(error)")
        }
#endif
        
        self.channelAvatarImageData = channelAvatarImageData
        self.videoThumbnailData = thumbnailData

        let isDownloaded: Bool
        
        if let downloadedVideo = PersistenceModel.shared.getDownloadedVideo(videoId: video.videoId) {
            self.streamingInfos = VideoInfosResponse.createEmpty()
            self.streamingInfos.streamingURL = downloadedVideo.storageLocation
            if let channel = downloadedVideo.channel {
                self.streamingInfos.channel = YTLittleChannelInfos(channelId: channel.channelId, name: channel.name)
            }
            self.streamingInfos.title = downloadedVideo.title
            self.streamingInfos.videoDescription = downloadedVideo.videoDescription
            
            self.videoThumbnailData = self.videoThumbnailData ?? downloadedVideo.thumbnail
            self.channelAvatarImageData = channelAvatarImageData ?? downloadedVideo.channel?.thumbnail
            self.chapters = downloadedVideo.chaptersArray.map({ .init(time: Int($0.startTimeSeconds), formattedTime: $0.shortTimeDescription, title: $0.title, thumbnailData: $0.thumbnail)
            })
            isDownloaded = true
        } else {
            guard NetworkReachabilityModel.shared.connected else { throw "Attempted to load a non-downloaded video while being offline." }
            
            await YTM.getVisitorData()
            
            do {
                self.streamingInfos = try await video.fetchStreamingInfosThrowing(youtubeModel: YTM)
                guard let streamingURL = streamingInfos.streamingURL else { throw "No streaming URL" }
                try await Self.testVideoFormat(url: streamingURL)
            } catch { // check with browser headers
                defer {
                    YTM.customHeaders[.videoInfos] = nil
                }
                Logger.atwyLogs.simpleLog("First streaming URL doesn't work, trying a new one")
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
                        "{\"context\":{\"client\":{\"deviceMake\":\"Apple\",\"deviceModel\":\"\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.5 Safari/605.1.15,gzip(gfe)\",\"clientName\":\"WEB\",\"clientVersion\":\"2.20250731.01.00\",\"osName\":\"Macintosh\",\"osVersion\":\"10_15_7\",\"platform\":\"DESKTOP\",\"clientFormFactor\":\"UNKNOWN_FORM_FACTOR\",\"configInfo\":{},\"screenDensityFloat\":2,\"userInterfaceTheme\":\"USER_INTERFACE_THEME_DARK\",\"timeZone\":\"Europe/Zurich\",\"browserName\":\"Safari\",\"browserVersion\":\"16.5\",\"acceptHeader\":\"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\",\"utcOffsetMinutes\":120,\"clientScreen\":\"WATCH\",\"mainAppWebInfo\":{\"graftUrl\":\"/watch?v=",
                        "&pp=YAHIAQE%3D\",\"webDisplayMode\":\"WEB_DISPLAY_MODE_BROWSER\",\"isWebNativeShareAvailable\":true}},\"user\":{\"lockedSafetyMode\":false},\"request\":{\"useSsl\":true,\"internalExperimentFlags\":[],\"consistencyTokenJars\":[]}},\"videoId\":\"",
                        "\",\"params\":\"YAHIAQE%3D\",\"playbackContext\":{\"contentPlaybackContext\":{\"vis\":5,\"splay\":false,\"autoCaptionsDefaultOn\":false,\"autonavState\":\"STATE_NONE\",\"html5Preference\":\"HTML5_PREF_WANTS\",\"signatureTimestamp\":19508,\"autoplay\":true,\"autonav\":true,\"referer\":\"https://www.youtube.com/\",\"lactMilliseconds\":\"-1\",\"watchAmbientModeContext\":{\"hasShownAmbientMode\":true,\"watchAmbientModeEnabled\":true}}},\"racyCheckOk\":false,\"contentCheckOk\":false}"
                    ],
                    parameters: [
                        .init(name: "prettyPrint", content: "false")
                    ]
                )
                
                await YTM.getVisitorData()
                
                let newStreamingInfo = try await video.fetchStreamingInfosThrowing(youtubeModel: YTM)
                
                guard let newStreamingURL = newStreamingInfo.streamingURL else {
                    throw "No second streaming URL"
                }
                self.streamingInfos = newStreamingInfo

                try await Self.testVideoFormat(url: newStreamingURL)
            }
            isDownloaded = false
        }
        guard let url = self.streamingInfos.streamingURL else { throw "Couldn't get streaming URL." }

        let asset: AVURLAsset
        
        if !isDownloaded {
            let components = NSURLComponents.init(url: url, resolvingAgainstBaseURL: true)
            components?.scheme = "customloader"
            asset = AVURLAsset(url: components!.url!)
            asset.resourceLoader.setDelegate(ressourceLoader, queue: .main)
            let audioFormats = self.streamingInfos.downloadFormats.compactMap { $0 as? AudioOnlyFormat }
            var originalLanguages = audioFormats.filter { $0.formatLocaleInfos?.isAutoDubbed != true }
            if originalLanguages.isEmpty {
                originalLanguages = audioFormats
            }
            ressourceLoader.defaultLanguage = originalLanguages.first(where: { $0.formatLocaleInfos?.isDefaultAudioFormat == true })?.formatLocaleInfos?.localeId ?? originalLanguages.first?.formatLocaleInfos?.localeId
        } else {
            asset = AVURLAsset(url: url)
        }
        
        super.init(asset: asset, automaticallyLoadedAssetKeys: nil)
        
        self.addMetadatas()
        if let thumbnailData = self.videoThumbnailData {
            self.setAndAppendImageData(imageData: thumbnailData)
            VideoPlayerModel.shared.setCurrentVideoThumbnailData(thumbnailData, videoId: self.videoId)
        }
        
        let startTime = PersistenceModel.shared.currentData.watchedVideos[self.videoId]?.watchedUntil ?? Double(self.video.startTime ?? 0)
        
        if startTime > 0 {
            await self.seek(to: CMTime(seconds: startTime, preferredTimescale: 600))
        }
        
        self.fetchMoreInfos()
    }
    
    private func addMetadatas() {
        let metadatas = Self.getMetadatasForInfos(title: self.video.title ?? "", channelName: self.video.channel?.name ?? self.streamingInfos.channel?.name ?? self.moreVideoInfos?.channel?.name ?? "", videoDescription: self.streamingInfos.videoDescription ?? "")
        for metadataItem in metadatas {
            self.setAndAppendMetdataItem(value: metadataItem.value, type: metadataItem.identifier, key: metadataItem.key)
        }
    }
    
    static func testVideoFormat(url: URL) async throws {
        let (hlsData, _) = try await URLSession.shared.data(from: url)
        
        let hlsStringParts = AssetRessourceLoader.removeUncompatibleFormats(fromPlaylist: String(decoding: hlsData, as: UTF8.self)).split(separator: "\n")
        
        let testingLinks = hlsStringParts.filter({ $0.hasPrefix("https://")  }).map(String.init).compactMap(URL.init(string:))
        
        guard let firstLink = testingLinks.first else { throw "No stream" }
        
        // TODO: remove the non-working links from the main playlist, maybe some others will work?
        if firstLink.pathExtension == "m3u8" {
            try await withThrowingTaskGroup(of: Void.self, body: { group in
                testingLinks.forEach { link in
                    group.addTask(operation: {
                        try await testVideoFormat(url: link)
                    })
                }
                try await group.waitForAll()
            })
        } else {
            var request = URLRequest(url: firstLink)
            request.httpMethod = "HEAD"
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if ((response as? HTTPURLResponse)?.statusCode ?? 400) != 200 {
                throw "Link doesn't work"
            }
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
                        VideoPlayerModel.shared.setCurrentVideoThumbnailData(thumbnailData, videoId: self.videoId)
                    }
                }
                fetchThumbnailOperation.start()
            }
            
            DispatchQueue.main.async {
                self.addMetadatas()
                self.isFetchingMoreVideoInfos = false
                
                self.update()
            }
            
            await self.fetchMoreRecommendedVideos()
            await self.fetchVideoComments()
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
                DispatchQueue.main.safeSync {
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
        guard !self.isFetchingComments, let comments  = self.comments, comments.continuationToken != nil else { return }
        
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
            
            self.comments?.results[commentIndex.commentIndex].replies = self.comments?.results[commentIndex.commentIndex].replies.unique({$0.commentIdentifier == $1.commentIdentifier}) ?? []
            return
        } else {
            self.comments?.results[commentIndex.commentIndex].replies.append(contentsOf: replies)
            self.comments?.results[commentIndex.commentIndex].actionsParams[.repliesContinuation] = newToken
            
            self.comments?.results[commentIndex.commentIndex].replies = self.comments?.results[commentIndex.commentIndex].replies.unique({$0.commentIdentifier == $1.commentIdentifier}) ?? []
            return
        }
    }
    
    func addComment(_ comment: YTComment, at index: Int = 0) {
        self.comments?.results.insert(comment, at: index)
    }
    
    func addReplyToComment(_ commentId: String, reply: YTComment) {
        guard let commentIndex = self.getCommentIndex(forId: commentId) else { return }

        self.comments?.results[commentIndex.commentIndex].replies.insert(reply, at: (commentIndex.replyIndex ?? -1) + 1)
    }
    
    func removeComment(withIdentifier identifier: String, animated: Bool) {
        self.comments?.results = self.comments?.results
            .filter {
                $0.commentIdentifier != identifier
            }
            .map { comment in
                var new = comment
                new.replies = new.replies.filter({$0.commentIdentifier != identifier}) // only one level of replies
                return new
            } ?? []
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
