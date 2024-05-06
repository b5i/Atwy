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

struct YTElementDataSet {
    var allowChannelLinking: Bool = true
    
    var removeFromPlaylistInfo: (playlistId: String, removeToken: String)? = nil
    
    var channelAvatarData: Data? = nil
    
    var thumbnailData: Data? = nil
}


struct YTVideoWithData {
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
