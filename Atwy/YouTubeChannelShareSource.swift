//
//  YouTubeChannelShareSource.swift
//  Atwy
//
//  Created by Antoine Bollengier on 26.03.2024.
//  Copyright © 2024-2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation
import UIKit
import YouTubeKit
import UniformTypeIdentifiers
import LinkPresentation

class YouTubeChannelShareSource: NSObject, UIActivityItemSource {
    let channel: YouTubeChannel
    
    var channelURL: URL { URL(string: "https://youtube.com/\((channel as? YTChannel)?.handle ?? "channel/" + channel.channelId)")! }
    
    init(channel: YouTubeChannel) {
        self.channel = channel
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return self.channelURL
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return self.channelURL
    }
    
    /// - Note: Does not seem to be active, maybe activityViewControllerLinkMetadata takes over it?
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return channel.name ?? ""
    }
    
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.originalURL = self.channelURL
        metadata.url = metadata.originalURL
        metadata.title = self.channel.name
        if let thumbnailURL = channel.thumbnails.maxFor(2)?.url {
            let downloadImageOperation = DownloadImageOperation(imageURL: thumbnailURL)
            downloadImageOperation.start()
            downloadImageOperation.waitUntilFinished()
            if let imageData = downloadImageOperation.imageData, let image = UIImage(data: imageData) {
                metadata.imageProvider = NSItemProvider(object: image)
            }
        } else {
            metadata.imageProvider = NSItemProvider(object: UIImage(systemName: "person.fill")!)
        }
        return metadata
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        return UTType.url.identifier
    }
}

