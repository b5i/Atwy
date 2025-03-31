//
//  YTPlaylistShareSource.swift
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

class YTPlaylistShareSource: NSObject, UIActivityItemSource {
    let playlist: YTPlaylist
    
    var playlistURL: URL { URL(string: "https://youtube.com/playlist?list=\(playlist.playlistId.hasPrefix("VL") ? String(playlist.playlistId.dropFirst(2)) : playlist.playlistId)")! }
    
    init(playlist: YTPlaylist) {
        self.playlist = playlist
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return self.playlistURL
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return self.playlistURL
    }
    
    /// - Note: Does not seem to be active, maybe activityViewControllerLinkMetadata takes over it?
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return playlist.title ?? ""
    }
    
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.originalURL = self.playlistURL
        metadata.url = metadata.originalURL
        metadata.title = self.playlist.title
        if let thumbnailURL = playlist.thumbnails.maxFor(2)?.url {
            let downloadImageOperation = DownloadImageOperation(imageURL: thumbnailURL)
            downloadImageOperation.start()
            downloadImageOperation.waitUntilFinished()
            if let imageData = downloadImageOperation.imageData, let image = UIImage(data: imageData) {
                metadata.imageProvider = NSItemProvider(object: image)
            }
        } else {
            metadata.imageProvider = NSItemProvider(object: UIImage(systemName: "rectangle.stack.badge.play")!)
        }
        return metadata
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        return UTType.url.identifier
    }
}
