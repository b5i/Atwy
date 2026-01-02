//
//  FavoriteVideo+toYTVideo.swift
//  Atwy
//
//  Created by Antoine Bollengier on 01.12.2023.
//  Copyright © 2023-2026 Antoine Bollengier. All rights reserved.
//

import Foundation
import YouTubeKit

public extension FavoriteVideo {
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
