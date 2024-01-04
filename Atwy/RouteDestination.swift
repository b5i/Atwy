//
//  Route.swift
//  Atwy
//
//  Created by Antoine Bollengier on 04.12.2023.
//

import Foundation
import SwiftUI
import YouTubeKit

public enum RouteDestination: Hashable {
    public static func == (lhs: RouteDestination, rhs: RouteDestination) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    case downloadings
    case googleConnection
    case licence(license: LicenseView.License)
    case usersPlaylists(playlists: [YTPlaylist])
    
    case channelDetails(channel: YTLittleChannelInfos)
    case playlistDetails(playlist: YTPlaylist)
    case history
    
    // Settings
    case behaviorSettings
    case appearanceSettings
    case storageSettings
    case licensesSettings
}

extension YTLittleChannelInfos: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.channelId)
    }
    
    public static func == (lhs: YTLittleChannelInfos, rhs: YTLittleChannelInfos) -> Bool {
        return lhs.channelId == rhs.channelId && lhs.name == rhs.name && lhs.thumbnails == rhs.thumbnails
    }
}

extension YTThumbnail: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.url)
    }
}

extension YTPlaylist: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.playlistId)
    }
}

extension YTVideo: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.videoId)
    }
}
