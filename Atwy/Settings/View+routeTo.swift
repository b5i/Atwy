//
//  View+routeTo.swift
//  Atwy
//
//  Created by Antoine Bollengier on 04.12.2023.
//

import Foundation
import SwiftUI

// Idea from https://twitter.com/Dimillian/status/1731583767817417159/photo/1
public extension View {
    @ViewBuilder func routeTo(_ type: RouteDestination) -> some View {
        NavigationLink(destination: {
            switch type {
            case .downloadings:
                DownloadingsView()
            case .googleConnection:
                GoogleConnectionView()
            case .licence(let license):
                LicenseView(license: license)
            case .usersPlaylists(let playlists):
                UsersPlaylistsListView(playlists: playlists)
            case .channelDetails(let channel):
                ChannelDetailsView(channel: channel)
            case .playlistDetails(let playlist):
                PlaylistDetailsView(playlist: playlist)
            case .history:
                HistoryView()
            case .behaviorSettings:
                BehaviorSettingsView()
            case .appearanceSettings:
                AppearanceSettingsView()
            case .storageSettings:
                StorageSettingsView()
            case .loggerSettings:
                LoggerSettingsView()
            case .licensesSettings:
                LicensesView()
            }
        }, label: {self})
//        navigationDestination(for: RouteDestination.self, destination: { destination in
//            switch destination {
//            case .downloadings:
//                DownloadingsView()
//            case .googleConnection:
//                GoogleConnectionView()
//            case .licence(let license):
//                LicenseView(license: license)
//            case .usersPlaylists(let playlists):
//                UsersPlaylistsListView(playlists: playlists)
//            case .channelDetails(let channel):
//                ChannelDetailsView(channel: channel)
//            case .playlistDetails(let playlist):
//                PlaylistDetailsView(playlist: playlist)
//            case .appearanceSettings:
//                AppearanceSettingsView()
//            case .storageSettings:
//                StorageSettingsView()
//            case .licensesSettings:
//                LicensesView()
//            }
//        })
    }
}
