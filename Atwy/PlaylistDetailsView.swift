//
//  PlaylistDetailsView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 22.01.23.
//

import SwiftUI
import InfiniteScrollViews
import YouTubeKit
import OSLog

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
                            let videosBinding: Binding<[YTElementWithData]> = Binding(get: {
                                var toReturn: [YTElementWithData] = []
                                for (video, token) in zip(model.playlistInfos?.results ?? [], model.playlistInfos?.videoIdsInPlaylist ?? Array(repeating: nil, count: model.playlistInfos?.results.count ?? 0)) {
                                    var videoData = YTElementDataSet()
                                    if let removalToken = token {
                                        videoData.removeFromPlaylistAvailable = {
                                            RemoveVideoFromPlaylistResponse.sendNonThrowingRequest(youtubeModel: YTM, data: [.movingVideoId: removalToken, .playlistEditToken: "CAFAAQ%3D%3D", .browseId: self.playlist.playlistId], result: { result in
                                                switch result {
                                                case .success(_):
                                                    if let removalIndex = self.model.playlistInfos?.videoIdsInPlaylist?.firstIndex(where: {$0 == token}) {
                                                        DispatchQueue.main.async {
                                                            _ = self.model.playlistInfos?.results.remove(at: removalIndex)
                                                        }
                                                    }
                                                case .failure(_):
                                                    break
                                                }
                                            })
                                        }
                                    }
                                    toReturn.append(
                                        YTElementWithData(element: video, data: videoData)
                                    )
                                }
                                return toReturn
                            }, set: { newValue in
                                model.playlistInfos?.results = newValue.compactMap({$0.element as? YTVideo})
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
                if VPM.currentItem != nil {
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
            // TODO: add the share option here too
#else
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
            if self.playlist.playlistId.hasPrefix("PL") || self.playlist.playlistId.hasPrefix("VLPL") { // avoid private playlists like history and watch later
                ToolbarItem(placement: .topBarTrailing) {
                    ShareButtonView(onTap: {
                        self.playlist.showShareSheet()
                    })
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
                PlaylistInfosResponse.sendNonThrowingRequest(youtubeModel: YTM, data: [.browseId: playlist.playlistId], useCookies: true, result: { result in
                    switch result {
                    case .success(let response):
                        DispatchQueue.main.async {
                            self.playlistInfos = response
                            if response.playlistId == nil {
                                self.playlistInfos?.playlistId = playlist.playlistId
                            }
                        }
                    case .failure(let error):
                        Logger.atwyLogs.simpleLog("Error while fetching playlist infos: \(error.localizedDescription)")
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
                PlaylistInfosResponse.Continuation.sendNonThrowingRequest(youtubeModel: YTM, data: [.continuation: continuationToken], useCookies: true, result: { result in
                    switch result {
                    case .success(let response):
                        DispatchQueue.main.async {
                            self.playlistInfos?.mergeWithContinuation(response)
                        }
                    case .failure(let error):
                        Logger.atwyLogs.simpleLog("Error while fetching playlist infos: \(error)")
                    }
                    DispatchQueue.main.async {
                        self.isFetchingContinuation = false
                    }
                })
            }
        }
        
        public func removeFromPlaylist(videoIdInPlaylist: String) {
            if let playlistInfos = playlistInfos, let playlistId = playlistInfos.playlistId, playlistInfos.userInteractions.isEditable ?? false {
                RemoveVideoFromPlaylistResponse.sendNonThrowingRequest(youtubeModel: YTM, data: [.movingVideoId: videoIdInPlaylist, .playlistEditToken: "CAFAAQ%3D%3D", .browseId: playlistId], result: { result in
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
                        Logger.atwyLogs.simpleLog("Couldn't remove video from playlist: \(error)")
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
                MoveVideoInPlaylistResponse.sendNonThrowingRequest(youtubeModel: YTM, data: data, result: { result in
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
                        Logger.atwyLogs.simpleLog("Couldn't move video in playlist: \(error)")
                    }
                })
            }
        }
    }
}

