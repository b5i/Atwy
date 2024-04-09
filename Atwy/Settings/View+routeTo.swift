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
    func routeTo(_ type: RouteDestination?) -> some View {
        NavigationLink(value: type, label: { self })
    }
    
    /// Apply this method to the container of the item that has the routeTo method
    func routeContainer() -> some View {
        self
            .navigationDestination(for: RouteDestination.self, destination: { destination in
                switch destination {
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
                case .privateAPIsSettings:
                    PrivateAPIsSettingsView()
                case .licensesSettings:
                    LicensesView()
                }
            })
    }
}
