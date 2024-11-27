//
//  UsersPlaylistsListView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 11.02.23.
//

import SwiftUI
import YouTubeKit

struct UsersPlaylistsListView: View {
    let playlists: [YTPlaylist]
    @StateObject private var model = Model()
    @State private var search: String = ""
    @ObservedObject private var APIM = APIKeyModel.shared
    @ObservedObject private var network = NetworkReachabilityModel.shared
    @ObservedObject private var VPM = VideoPlayerModel.shared
    @ObservedObject private var NRM = NetworkReachabilityModel.shared
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, content: {
                LazyVStack {
                    Color.clear.frame(width: 0, height: 20)
                    let playlistsToDisplay: [YTPlaylist] = search.isEmpty ? model.playlists ?? playlists : (model.playlists ?? playlists).filter({$0.title?.contains(search) ?? false})
                    ForEach(Array(playlistsToDisplay.enumerated()), id: \.offset) { _, playlist in
                        PlaylistView(playlist: playlist)
                            .padding(.horizontal, 5)
                            .frame(width: geometry.size.width, height: 180)
                            .routeTo(.playlistDetails(playlist: playlist))
                    }
                    Color.clear.frame(width: 0, height: (VPM.currentItem != nil) ? 50 : 0)
                }
            })
#if os(macOS)
            .searchable(text: $search, placement: .toolbar)
#else
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always))
#endif
        }
        .onAppear {
            self.model.getPlaylists()
        }
        .navigationTitle("Playlists")
        .customNavigationTitleWithRightIcon {
            ShowSettingsButtonView()
        }
    }
    
    private class Model: ObservableObject {
        @Published private(set) var playlists: [YTPlaylist]? = nil
        
        private var isFetching: Bool = false
        
        func getPlaylists() {
            guard !isFetching else { return }
            
            self.isFetching = true
            
            AccountPlaylistsResponse.sendNonThrowingRequest(youtubeModel: YTM, data: [:], result: { result in
                self.isFetching = false
                switch result {
                case .success(let success):
                    DispatchQueue.main.async {
                        self.playlists = success.results
                    }
                case .failure(let failure):
                    print(failure.localizedDescription)
                }
            })
        }
    }
}
