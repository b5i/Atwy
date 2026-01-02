//
//  PersonnalAccountView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 10.02.23.
//  Copyright © 2023-2026 Antoine Bollengier. All rights reserved.
//

import SwiftUI
import YouTubeKit
import OSLog

struct PersonnalAccountView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var VPM = VideoPlayerModel.shared
    @State private var libraryContent: AccountLibraryResponse?
    @State private var isFetching: Bool = false
    var body: some View {
        GeometryReader { geometry in
            VStack {
                if isFetching {
                    LoadingView()
                        .padding()
                        .centered()
                } else {
                    ScrollView(.vertical, content: {
                        VStack(spacing: 50) {
                            if let libraryContent = libraryContent {
                                if let history = libraryContent.history {
                                    YouTubeBasePlaylistView(playlist: history, customRoute: .history)
                                        .frame(width: geometry.size.width, height: history.frontVideos.count > 0 ? geometry.size.height * 0.25 : geometry.size.height * 0.05)
                                }
                                if let watchLater = libraryContent.watchLater {
                                    YouTubeBasePlaylistView(playlist: watchLater)
                                        .frame(width: geometry.size.width, height: watchLater.frontVideos.count > 0 ? geometry.size.height * 0.25 : geometry.size.height * 0.05)
                                }
                                if let likes = libraryContent.likes {
                                    YouTubeBasePlaylistView(playlist: likes)
                                        .frame(width: geometry.size.width, height: likes.frontVideos.count > 0 ? geometry.size.height * 0.25 : geometry.size.height * 0.05)
                                }
                                VStack {
                                    VStack {
                                        HStack {
                                            Text("Playlists")
                                                .font(.title2)
                                                .padding()
                                                .foregroundColor(colorScheme.textColor)
                                            Spacer()
                                        }
                                        HStack {
                                            PlaylistsStackView(playlists: libraryContent.playlists)
                                                .frame(width: geometry.size.width)
                                        }
                                    }
                                    .routeTo(.usersPlaylists(playlists: libraryContent.playlists))
                                }
                                .frame(width: geometry.size.width, height: geometry.size.height * 0.3)
                            }
                        }
                    })
                    .scrollIndicators(.hidden)
                    .contentMargins(.bottom, length: VPM.currentItem != nil ? 70 : 0)
                }
            }
            .routeContainer()
        }
        .onAppear {
            if self.libraryContent == nil, !self.isFetching {
                getUsersPlaylists()
            }
        }
    }
    
    private func getUsersPlaylists() {
        DispatchQueue.main.async {
            self.isFetching = true
        }
        AccountLibraryResponse.sendNonThrowingRequest(youtubeModel: YTM, data: [:], result: { result in
            switch result {
            case .success(var response):
                if response.history?.title == "" {
                    response.history?.title = "History"
                }
                response.history?.frontVideos = []
                
                if response.likes?.title == "" {
                    response.likes?.title = "Liked videos"
                }
                
                if response.watchLater?.title == "" {
                    response.watchLater?.title = "Watch Later"
                }
                
                DispatchQueue.main.async {
                    self.libraryContent = response
                }
            case .failure(let error):
                Logger.atwyLogs.simpleLog("Error while fetching account's library: \(String(describing: error)).")
            }
            DispatchQueue.main.async {
                self.isFetching = false
            }
        })
    }
    
    private struct PlaylistsStackView: View {
        @Environment(\.colorScheme) private var colorScheme
        let playlists: [YTPlaylist]
        var body: some View {
            VStack {
                GeometryReader { geometry in
                    ZStack {
                        ForEach(Array(playlists.dropLast((playlists.count > 3) ? playlists.count - 4 : 0).reversed().enumerated()), id: \.offset) { item in
                            let scaleLevel: Double = Double(item.offset) * 0.05 + 0.85
                            let opactityLevel: Double = Double(item.offset) * 0.1 + 0.70
                            PlaylistView.ImageOfPlaylistView(playlist: item.element)
                                .frame(width: geometry.size.width * 0.5, height: geometry.size.height)
                                .padding(.trailing, CGFloat(item.offset) * 50)
                                .scaleEffect(scaleLevel)
                                .shadow(radius: 3)
                                .overlay {
                                    Rectangle()
                                        .foregroundColor(colorScheme.backgroundColor)
                                        .opacity(1 - opactityLevel)
                                }
                        }
                        VStack {
                            Text(String(playlists.count))
                                .font(.title2)
                                .foregroundColor(colorScheme.textColor)
                            Image(systemName: "text.justify.left")
                                .resizable()
                                .scaledToFit()
                                .font(.title2)
                                .foregroundColor(colorScheme.textColor)
                        }
                        .frame(width: 60, height: 60)
                        .padding(.leading, geometry.size.width * 0.8+10)
                    }
                }
            }
        }
    }
}
