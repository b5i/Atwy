//
//  UsersPlaylistsListView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 11.02.23.
//

import SwiftUI
import YouTubeKit

struct UsersPlaylistsListView: View {
    @State var playlists: [YTPlaylist]
    @State private var search: String = ""
    @ObservedObject private var APIM = APIKeyModel.shared
    @ObservedObject private var network = NetworkReachabilityModel.shared
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView(.vertical, content: {
                    LazyVStack {
                        Color.clear.frame(width: 0, height: 20)
                        let playlistsToDisplay: [YTPlaylist] = search.isEmpty ? playlists : playlists.filter({$0.title?.contains(search) ?? false})
                        ForEach(Array(playlistsToDisplay.enumerated()), id: \.offset) { _, playlist in
                            NavigationLink(
                                destination: PlaylistDetailsView(playlist: playlist),
                                label: {
                                    PlaylistView(playlist: playlist)
                                        .padding(.horizontal, 5)
                                })
                            .frame(width: geometry.size.width, height: 180)
                        }
                    }
                })
#if os(macOS)
                .searchable(text: $search, placement: .toolbar)
#else
                .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always))
#endif
            }
        }
        .navigationTitle("Playlists")
        .toolbar(content: {
            ShowSettingsButton()
        })
    }
}
