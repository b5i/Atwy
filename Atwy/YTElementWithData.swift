//
//  YTElementWithData.swift
//  Atwy
//
//  Created by Antoine Bollengier on 03.05.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation
import YouTubeKit

struct YTElementWithData {
    var id: Int? { self.element.id }
    
    var element: any YTSearchResult
    
    var data: YTElementDataSet
}

struct YTElementDataSet: Hashable {
    typealias VideoViewMode = PreferencesStorageModel.Properties.VideoViewModes
    
    static func == (lhs: YTElementDataSet, rhs: YTElementDataSet) -> Bool {
        return lhs.allowChannelLinking == rhs.allowChannelLinking && (lhs.removeFromPlaylistAvailable == nil) == (rhs.removeFromPlaylistAvailable == nil) && lhs.channelAvatarData == rhs.channelAvatarData && lhs.thumbnailData == rhs.thumbnailData && lhs.videoViewMode == rhs.videoViewMode
    }
    
    var allowChannelLinking: Bool = true
    
    var removeFromPlaylistAvailable: (() -> Void)? = nil
    
    var channelAvatarData: Data? = nil
    
    var thumbnailData: Data? = nil
    
    var videoViewMode: VideoViewMode = (PreferencesStorageModel.shared.propetriesState[.videoViewMode] as? VideoViewMode) ?? .fullThumbnail
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.allowChannelLinking)
        hasher.combine(self.removeFromPlaylistAvailable == nil)
        hasher.combine(self.channelAvatarData)
        hasher.combine(self.thumbnailData)
        hasher.combine(self.videoViewMode)
    }
}


struct YTVideoWithData: Hashable {
    
    var video: YTVideo
    
    var data: YTElementDataSet
}

extension YTVideo {
    func withData(_ data: YTElementDataSet? = nil) -> YTVideoWithData {
        return YTVideoWithData(video: self, data: data ?? .init())
    }
}

struct YTPlaylistWithData {    
    var playlist: YTPlaylist
    
    var data: YTElementDataSet
}

extension YTPlaylist {
    func withData(_ data: YTElementDataSet? = nil) -> YTPlaylistWithData {
        return YTPlaylistWithData(playlist: self, data: data ?? .init())
    }
}
