//
//  FavoritesView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 02.12.22.
//

import SwiftUI
import CoreData
import YouTubeKit

struct FavoritesView: View {
    @State var favorites1: [FavoriteVideo] = []
    @State private var search: String = ""
    @ObservedObject private var NPM = navigationPathModel
    @ObservedObject private var VPM = VideoPlayerModel.shared
    @ObservedObject private var APIM = APIKeyModel.shared
    @ObservedObject private var network = NetworkReachabilityModel.shared
    @ObservedObject private var PSM = PreferencesStorageModel.shared
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    LazyVStack {
                        ForEach(favorites1) { video in
                            let convertResult = YTVideo(id: Int(video.timestamp.timeIntervalSince1970),
                                                        videoId: video.videoId,
                                                        title: video.title,
                                                        channel: video.channel != nil ? .init(channelId: video.channel!.channelId, name: video.channel?.name) : nil,
                                                        timeLength: video.timeLength)
                            
                            Button {
                                if VideoPlayerModel.shared.video?.videoId != video.videoId {
                                    VideoPlayerModel.shared.loadVideo(video: convertResult)
                                }
                                
                                SheetsModel.shared.showSheet(.watchVideo)
                            } label: {
                                if let state = PSM.propetriesState[.videoViewMode] as? PreferencesStorageModel.Properties.VideoViewModes, state == .halfThumbnail {
                                    VideoFromSearchView(video: convertResult, videoThumbnailData: video.thumbnailData, channelAvatarData: video.channel?.thumbnail)
                                        .frame(width: geometry.size.width, height: 180, alignment: .center)
                                } else {
                                    // Big thumbnail view by default
                                    VideoFromSearchView(video: convertResult, videoThumbnailData: video.thumbnailData, channelAvatarData: video.channel?.thumbnail)
                                        .frame(width: geometry.size.width, height: geometry.size.width * 9/16 + 90, alignment: .center)
                                }
                            }
                            .listRowSeparator(.hidden)
                        }
                        Color.clear
                            .frame(height: 30)
                    }
                    if VPM.video != nil {
                        Color.clear
                            .frame(height: 50)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
#if os(macOS)
                .searchable(text: $search, placement: .toolbar)
#else
                .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always))
#endif
                
                .autocorrectionDisabled(true)
                .navigationTitle("Favorites")
                .toolbar(content: {
                    ShowSettingsButton()
                })
        }
        .task {
            self.updateFavoritesList()
            NotificationCenter.default.addObserver(
                forName: Notification.Name("CoreDataChanged"),
                object: nil,
                queue: nil,
                using: { _ in
                    Task {
                        await updateFavoritesList()
                    }
                })
        }
    }

    func updateFavoritesList() {
        let fetchRequest = FavoriteVideo.fetchRequest()
        do {
            var result = try PersistenceModel.shared.context.fetch(fetchRequest)
            result = result.filter({(search.isEmpty) ? true : $0.title?.contains(search) ?? false || $0.channel?.name?.contains(search) ?? false})
            result = result.filter({ favorite in
                if !NetworkReachabilityModel.shared.connected {
                    return PersistenceModel.shared.getStorageLocationFor(video: YTVideo(videoId: favorite.videoId)) != nil
                }
                return true
            })
            DispatchQueue.main.async {
                favorites1 = result
            }
        } catch {
            print(error)
            DispatchQueue.main.async {
                favorites1 = []
            }
        }
    }
}

struct IsPresentedSearchableModifier: ViewModifier {
    @Binding var search: String
    @Binding var isPresented: Bool
    @State var placement: SearchFieldPlacement = .automatic
    func body(content: Content) -> some View {
        Group {
            if isPresented {
                content
                    .searchable(text: $search, placement: placement)
            } else {
                content
            }
        }
    }
}

extension View {
    func isPresentedSearchable(search: Binding<String>, isPresented: Binding<Bool>, placement: SearchFieldPlacement = .automatic) -> some View {
        modifier(IsPresentedSearchableModifier(search: search, isPresented: isPresented, placement: placement))
    }
}
