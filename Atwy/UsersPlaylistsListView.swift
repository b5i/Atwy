//
//  UsersPlaylistsListView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 11.02.23.
//  Copyright © 2023-2025 Antoine Bollengier. All rights reserved.
//

import SwiftUI
import YouTubeKit

struct UsersPlaylistsListView: View {
    let playlists: [YTPlaylist]
    @StateObject private var model: Model
    @State private var search: String = ""
    @ObservedObject private var VPM = VideoPlayerModel.shared
    
    init(playlists: [YTPlaylist]) {
        self.playlists = playlists
        self._model = StateObject(wrappedValue: Model(defaultPlaylists: playlists))
    }
    
    var body: some View {
        VStack {
            if model.isFetching {
                LoadingView()
            } else {
                GeometryReader { geometry in
                    ScrollView(.vertical) {
                        LazyVStack {
                            Color.clear.frame(width: 0, height: 20)
                            let playlistsToDisplay: [YTPlaylist] = search.isEmpty ? model.playlists ?? playlists : (model.playlists ?? playlists).filter({$0.title?.contains(search) ?? false})
                            ForEach(Array(playlistsToDisplay.enumerated()), id: \.offset) { _, playlist in
                                PlaylistView(playlist: playlist)
                                    .padding(.horizontal, 5)
                                    .frame(width: geometry.size.width, height: 180)
                                    .routeTo(.playlistDetails(playlist: playlist))
                            }
                        }
                    }
                    .contentMargins(.bottom, length: VPM.currentItem != nil ? 70 : 0)
#if os(macOS)
                    .searchable(text: $search, placement: .toolbar)
#else
                    .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always))
#endif
                }
            }
        }
        .onAppear {
            self.model.getPlaylists()
        }
        .refreshable {
            self.model.getPlaylists(forceRefresh: true)
        }
        .navigationTitle("Playlists")
        .customNavigationTitleWithRightIcon {
            ShowSettingsButtonView()
        }
    }
    
    private class Model: ObservableObject {
        @Published private(set) var playlists: [YTPlaylist]? = nil
        
        init(defaultPlaylists: [YTPlaylist]?) {
            self.defaultPlaylists = defaultPlaylists
        }
        
        private var defaultPlaylists: [YTPlaylist]?
        
        @Published private(set) var isFetching: Bool = false
        
        func getPlaylists(forceRefresh: Bool = false) {
            guard !isFetching else { return }
            guard forceRefresh || playlists == nil else { return }
            
            DispatchQueue.main.safeSync {
                self.isFetching = true
            }
            
            AccountPlaylistsResponse.sendNonThrowingRequest(youtubeModel: YTM, data: [:], result: { result in
                switch result {
                case .success(let success):
                    self.defaultPlaylists = success.results
                    DispatchQueue.main.async {
                        self.playlists = success.results
                        self.isFetching = false
                    }
                case .failure(let failure):
                    print(failure.localizedDescription)
                    DispatchQueue.main.async {
                        if let defaultPlaylists = self.defaultPlaylists {
                            self.playlists = defaultPlaylists
                        }
                        self.isFetching = false
                    }
                }
            })
        }
    }
}
