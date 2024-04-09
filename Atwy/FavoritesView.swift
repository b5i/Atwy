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
    @Environment(\.colorScheme) private var colorScheme
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FavoriteVideo.timestamp, ascending: true)],
        animation: .default)
    private var favorites: FetchedResults<FavoriteVideo>
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
                        let propertyState = PSM.propetriesState[.videoViewMode] as? PreferencesStorageModel.Properties.VideoViewModes
                        let videoViewHeight = propertyState == .halfThumbnail ? 180 : geometry.size.width * 9/16 + 90
                        
                        ForEach(sortedVideos) { (video: FavoriteVideo) in
                            let convertResult = video.toYTVideo()
                            
                            Button {
                                if VideoPlayerModel.shared.currentItem?.videoId != video.videoId {
                                    VideoPlayerModel.shared.loadVideo(video: convertResult)
                                }
                                
                                SheetsModel.shared.showSheet(.watchVideo)
                            } label: {
                                VideoFromSearchView(video: convertResult, videoThumbnailData: video.thumbnailData, channelAvatarData: video.channel?.thumbnail)
                                    .frame(width: geometry.size.width, height: videoViewHeight, alignment: .center)
                            }
                            .listRowSeparator(.hidden)
                        }
                        Color.clear
                            .frame(height: 30)
                    }
                    if VPM.currentItem != nil {
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
                .sortingModeSelectorButton(forPropertyType: .favoritesSortingMode)
                .customNavigationTitleWithRightIcon {
                    ShowSettingsButtonView()
                }
        }
    }
    
    var sortedVideos: [FavoriteVideo] {
        return self.favorites.filter({$0.matchesQuery(search)}).sorted(by: {
            switch (self.PSM.propetriesState[.favoritesSortingMode] as? PreferencesStorageModel.Properties.SortingModes) ?? .oldest {
            case .newest:
                return $0.timestamp > $1.timestamp
            case .oldest:
                return $0.timestamp < $1.timestamp
            case .title:
                return ($0.title ?? "") < ($1.title ?? "")
            case .channelName:
                return ($0.channel?.name ?? "") < ($1.channel?.name ?? "")
            }
        })
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
