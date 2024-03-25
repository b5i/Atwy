//
//  YTVideoShareSource.swift
//  Atwy
//
//  Created by Antoine Bollengier on 25.03.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation
import UIKit
import YouTubeKit
import UniformTypeIdentifiers
import LinkPresentation

class YTVideoShareSource: NSObject, UIActivityItemSource {
    let video: YTVideo
    let thumbnailData: Data?
    
    var videoURL: URL { URL(string: "https://youtu.be/\(video.videoId)")! }
    
    init(video: YTVideo, thumbnailData: Data? = nil) {
        self.video = video
        self.thumbnailData = thumbnailData
        
        
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return self.videoURL
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return self.videoURL
    }
    
    /// - Note: Does not seem to be active, maybe activityViewControllerLinkMetadata takes over it?
    func activityViewController(_ activityViewController: UIActivityViewController, thumbnailImageForActivityType activityType: UIActivity.ActivityType?, suggestedSize size: CGSize) -> UIImage? {
        if let thumbnailData = self.thumbnailData {
            return UIImage(data: thumbnailData)
        } else if let thumbnailData = PersistenceModel.shared.getDownloadedVideo(videoId: video.videoId)?.thumbnail {
            return UIImage(data: thumbnailData)
        }
        return nil
    }
    
    /// - Note: Does not seem to be active, maybe activityViewControllerLinkMetadata takes over it?
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return video.title ?? ""
    }
    
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.originalURL = self.videoURL
        metadata.url = metadata.originalURL
        metadata.title = self.video.title
        if let downloadedVideo = PersistenceModel.shared.getDownloadedVideo(videoId: video.videoId), let thumbnailData = downloadedVideo.thumbnail, let image = UIImage(data: thumbnailData) {
                metadata.imageProvider = NSItemProvider(object: image)
        } else if let thumbnailURL = video.thumbnails.maxFor(2)?.url {
            let downloadImageOperation = DownloadImageOperation(imageURL: thumbnailURL)
            downloadImageOperation.start()
            downloadImageOperation.waitUntilFinished()
            if let imageData = downloadImageOperation.imageData, let image = UIImage(data: imageData) {
                metadata.imageProvider = NSItemProvider(object: image)
            }
        } else {
            metadata.imageProvider = NSItemProvider(object: UIImage(systemName: "play.rectangle")!)
        }
        return metadata
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        return UTType.url.identifier
    }
    
    /* TODO: Maybe add the videoURL to the metadata
    func loadRemoteURLSynchronously(forMetadata metadata: LPLinkMetadata) {
        let semaphore = DispatchSemaphore(value: 0)
        video.fetchStreamingInfos(youtubeModel: YTM) { result in
            guard case .success(let response) = result else { return }
            metadata.remoteVideoURL = response.streamingURL
            semaphore.signal()
        }
        semaphore.wait()
    }*/
}
