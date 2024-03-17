//
//  PlaylistDetailsView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 22.01.23.
//

import SwiftUI
import InfiniteScrollViews
import YouTubeKit

struct PlaylistDetailsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    let playlist: YTPlaylist
    @State private var navigationTitle: String = ""
    @State private var shouldReloadScrollView: Bool = false
    @StateObject private var model = Model()
    @ObservedObject private var APIM = APIKeyModel.shared
    @ObservedObject private var VPM = VideoPlayerModel.shared
    @ObservedObject private var network = NetworkReachabilityModel.shared
    private let changeIndex: Int = 0
    var body: some View {
        GeometryReader { geometry in
            //    ScrollView {
            let topPaddingForInformations: CGFloat = (playlist.channel?.name != nil ? 30 : 0) + ((model.playlistInfos?.viewCount != nil || playlist.timePosted != nil || model.playlistInfos?.videoCount != nil) ? 30 : 0)
            VStack(spacing: 0) {
                if model.isFetchingInfos {
                    LoadingView()
                } else {
                    VStack {
                        if model.playlistInfos?.results != nil {
                            let videosBinding: Binding<[any YTSearchResult]> = Binding(get: {
                                return model.playlistInfos?.results ?? []
                            }, set: { newValue in
                                model.playlistInfos?.results = newValue.compactMap({$0 as? YTVideo})
                            })
                            ElementsInfiniteScrollView(
                                items: videosBinding,
                                shouldReloadScrollView: $shouldReloadScrollView,
                                fetchMoreResultsAction: {
                                    model.fetchPlaylistContinuation()
                                }
                            )
                        }
                    }
                    .customHeaderView({
                            VStack {
                                if let channelName = playlist.channel?.name {
                                    Text(channelName)
                                        .font(.title3)
                                        .frame(height: 30)
                                }
                                if model.playlistInfos?.viewCount != nil || playlist.timePosted != nil || model.playlistInfos?.videoCount != nil {
                                    HStack {
                                        Text(model.playlistInfos?.videoCount ?? "")
                                            .foregroundColor(colorScheme.textColor)
                                            .font(.footnote)
                                            .opacity(0.5)
                                        if (model.playlistInfos?.viewCount != nil || playlist.timePosted != nil) && model.playlistInfos?.videoCount != nil {
                                            Divider()
                                        }
                                        Text(model.playlistInfos?.viewCount ?? "")
                                            .foregroundColor(colorScheme.textColor)
                                            .font(.footnote)
                                            .opacity(0.5)
                                        if model.playlistInfos?.viewCount != nil, playlist.timePosted != nil {
                                            Divider()
                                        }
                                        Text(playlist.timePosted ?? "")
                                            .foregroundColor(colorScheme.textColor)
                                            .font(.footnote)
                                            .opacity(0.5)
                                    }
                                    .frame(height: 20)
                                }
                            }
                            .padding(.horizontal)
                        //}
                        //.frame(width: geometry.size.width, height: topPaddingForInformations)
                    }, height: topPaddingForInformations)
                    //.padding(.top, topPaddingForInformations)
                }
                if VPM.video != nil {
                    Color.clear.frame(width: 0, height: 70)
                }
            }
            .onAppear {
                if model.playlistInfos == nil {
                    model.fetchPlaylistInfos(playlist: playlist)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
#if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
//        .navigationTitle(navigationTitle)
        .navigationTitle(playlist.title ?? "")
        .toolbar(content: {
#if os(macOS)
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
#else
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
#endif
        })
        .navigationBarBackButtonHidden(true)
        .customNavigationTitleWithRightIcon {
            ShowSettingsButtonView()
        }
    }
    
    private class Model: ObservableObject {
        @Published var playlistInfos: PlaylistInfosResponse?
        @Published var isFetchingInfos: Bool = false
        @Published var isFetchingContinuation: Bool = false
        
        public func fetchPlaylistInfos(playlist: YTPlaylist) {
            if !self.isFetchingInfos {
                DispatchQueue.main.async {
                    self.isFetchingInfos = true
                }
                PlaylistInfosResponse.sendRequest(youtubeModel: YTM, data: [.browseId: playlist.playlistId], useCookies: true, result: { result in
                    switch result {
                    case .success(let response):
                        DispatchQueue.main.async {
                            self.playlistInfos = response
                            if response.playlistId == nil {
                                self.playlistInfos?.playlistId = playlist.playlistId
                            }
                        }
                    case .failure(let error):
                        print("Error while fetching playlist infos: \(error.localizedDescription)")
                    }
                    DispatchQueue.main.async {
                        self.isFetchingInfos = false
                    }
                })
            }
        }
        
        public func fetchPlaylistContinuation() {
            if !self.isFetchingContinuation, let continuationToken = playlistInfos?.continuationToken {
                DispatchQueue.main.async {
                    self.isFetchingContinuation = true
                }
                PlaylistInfosResponse.Continuation.sendRequest(youtubeModel: YTM, data: [.continuation: continuationToken], useCookies: true, result: { result in
                    switch result {
                    case .success(let response):
                        self.playlistInfos?.mergeWithContinuation(response)
                    case .failure(let error):
                        print("Error while fetching playlist infos: \(error)")
                    }
                    DispatchQueue.main.async {
                        self.isFetchingContinuation = false
                    }
                })
            }
        }
        
        public func removeFromPlaylist(videoIdInPlaylist: String) {
            if let playlistInfos = playlistInfos, let playlistId = playlistInfos.playlistId, playlistInfos.userInteractions.isEditable ?? false {
                RemoveVideoFromPlaylistResponse.sendRequest(youtubeModel: YTM, data: [.movingVideoId: videoIdInPlaylist, .playlistEditToken: "CAFAAQ%3D%3D", .browseId: playlistId], result: { result in
                    switch result {
                    case .success(let response):
                        if response.success, let removedVideoIndex =
                            playlistInfos.videoIdsInPlaylist?.firstIndex(where: { $0 == videoIdInPlaylist }) {
                            DispatchQueue.main.async {
                                _ = self.playlistInfos?.videoIdsInPlaylist?.remove(at: removedVideoIndex)
                                self.playlistInfos?.results.remove(at: removedVideoIndex)
                            }
                        }
                    case .failure(let error):
                        print("Couldn't remove video from playlist: \(error)")
                    }
                })
            }
        }
        
        public func moveVideoInPlaylist(videoBeforeIdInPlaylist: String?, videoIdInPlaylist: String) {
            if let playlistInfos = playlistInfos, let playlistId = playlistInfos.playlistId, playlistInfos.userInteractions.canReorder ?? false {
                var data: [YouTubeKit.HeadersList.AddQueryInfo.ContentTypes: String] = [.movingVideoId: videoIdInPlaylist, .browseId: playlistId]
                if let videoBeforeIdInPlaylist = videoBeforeIdInPlaylist {
                    data[.videoBeforeId] = videoBeforeIdInPlaylist
                }
                MoveVideoInPlaylistResponse.sendRequest(youtubeModel: YTM, data: data, result: { result in
                    switch result {
                    case .success(let response):
                        if response.success {
                            if videoBeforeIdInPlaylist != nil, let videoBeforeIndex = playlistInfos.videoIdsInPlaylist?.firstIndex(where: {$0 == videoBeforeIdInPlaylist}), let movingVideoIndex = playlistInfos.videoIdsInPlaylist?.firstIndex(where: {$0 == videoIdInPlaylist}) {
                                DispatchQueue.main.async {
                                    self.playlistInfos?.videoIdsInPlaylist?.swapAt(videoBeforeIndex, movingVideoIndex)
                                    self.playlistInfos?.results.swapAt(videoBeforeIndex, movingVideoIndex)
                                }
                            } else if let movingVideoIndex = playlistInfos.videoIdsInPlaylist?.firstIndex(where: {$0 == videoIdInPlaylist}) {
                                let element = self.playlistInfos?.results[movingVideoIndex]
                                if let element = element {
                                    DispatchQueue.main.async {
                                        self.playlistInfos?.results.remove(at: movingVideoIndex)
                                        self.playlistInfos?.videoIdsInPlaylist?.remove(at: movingVideoIndex)
                                        self.playlistInfos?.results.insert(element, at: 0)
                                        self.playlistInfos?.videoIdsInPlaylist?.insert(videoBeforeIdInPlaylist, at: 0)
                                    }
                                }
                            }
                        }
                    case .failure(let error):
                        print("Couldn't move video in playlist: \(error)")
                    }
                })
            }
        }
    }
}

