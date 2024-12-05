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
    case consoleSettings
    case loggerSettings
    case privateAPIsSettings
    case licensesSettings
}

extension YTLittleChannelInfos {
    
    public static func == (lhs: YTLittleChannelInfos, rhs: YTLittleChannelInfos) -> Bool {
        return lhs.channelId == rhs.channelId && lhs.name == rhs.name && lhs.thumbnails == rhs.thumbnails
    }
}

