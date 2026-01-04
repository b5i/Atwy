//
//  LocalVideo.swift
//  Atwy
//
//  Created by Antoine Bollengier on 04.01.2026.
//  Copyright © 2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation
import CoreData
import YouTubeKit

protocol LocalVideo: NSFetchRequestResult, Identifiable {
    var videoId: String { get set }
    var timeLength: String? { get set }
    var timestamp: Date { get set }
    var thumbnailData: Data? { get set }
    var title: String? { get set }
    var channel: DownloadedChannel? { get set }
    
    static func fetchRequest() -> NSFetchRequest<Self>
    
    static var sortSetting: ReferenceWritableKeyPath<PreferencesStorageModel, PreferencesStorageModel.SortingModes> { get }
}

extension LocalVideo {
    func toYTVideo() -> YTVideo {
        return YTVideo(
            id: Int(self.timestamp.timeIntervalSince1970),
            videoId: self.videoId,
            title: self.title,
            channel: self.channel != nil ? .init(channelId: self.channel!.channelId, name: self.channel?.name) : nil,
            timeLength: self.timeLength
        )
    }
}
