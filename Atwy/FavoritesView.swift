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
                        
                        ForEach(favorites.filter({$0.matchesQuery(search)})) { (video: FavoriteVideo) in
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
            /*
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing, content: {
                        Menu {
                            Button {
                                
                            } label: {
                                Text("Newest")
                                Image(systemName: "arrow.up.to.line.compact")
                                    .resizable()
                                    .scaledToFit()
                            }
                            Button {
                                
                            } label: {
                                Text("Oldest")
                                Image(systemName: "arrow.down.to.line.compact")
                                    .resizable()
                                    .scaledToFit()
                            }
                            Button {
                                
                            } label: {
                                Text("Title")
                                Image(systemName: "music.note")
                                    .resizable()
                                    .scaledToFit()
                            }
                            Button {
                                
                            } label: {
                                Text("Channel")
                                Image(systemName: "music.mic")
                                    .resizable()
                                    .scaledToFit()
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(colorScheme.textColor.opacity(0.5))
                                    .frame(width: 30)
                                Circle()
                                    .fill(.regularMaterial)
                                    .frame(width: 30)
                                Image(systemName: "line.3.horizontal.decrease") // or arrow.up.and.down.text.horizontal arrow.up.arrow.down.circle
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18)
                            }
                        }
                    })
                }*/
                .customNavigationTitleWithRightIcon {
                    ShowSettingsButtonView()
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
