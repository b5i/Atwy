//
//  DownloadedVideosView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 27.11.22.
//

import SwiftUI
import YouTubeKit

struct DownloadedVideosView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DownloadedVideo.timestamp, ascending: true)],
        animation: .default)
    private var downloadedVideos: FetchedResults<DownloadedVideo>
    @State private var search: String = ""
    @ObservedObject private var DM = DownloadingsModel.shared
    @ObservedObject private var VPM = VideoPlayerModel.shared
    @ObservedObject private var NPM = navigationPathModel
    @ObservedObject private var APIM = APIKeyModel.shared
    @ObservedObject private var network = NetworkReachabilityModel.shared
    @ObservedObject private var PSM = PreferencesStorageModel.shared
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack {
                    if (DM.activeDownloadingsCount != 0) {
                        List {
                            HStack {
                                Text("Downloading")
                                Spacer()
                                Text("\(DM.activeDownloadingsCount)")
                                    .padding(.horizontal)
                                ProgressView()
                            }
                            .routeTo(.downloadings)
                        }
                        .frame(height: 50)
                        .padding()
                    }
                    ScrollView {
                        //                        List {
                        LazyVStack {
                            ForEach(downloadedVideos.filter({$0.matchesQuery(search)}), id: \.timestamp, content: { video in
                                let convertResult = video.toYTVideo()
                                Button {
                                    if VideoPlayerModel.shared.video?.videoId != video.videoId {
                                        VideoPlayerModel.shared.loadVideo(video: convertResult)
                                    }
                                    SheetsModel.shared.showSheet(.watchVideo)
                                } label: {
                                    if let state = PSM.propetriesState[.videoViewMode] as? PreferencesStorageModel.Properties.VideoViewModes, state == .halfThumbnail {
                                        VideoFromSearchView(video: convertResult, videoThumbnailData: video.thumbnail, channelAvatarData: video.channel?.thumbnail)
                                            .frame(width: geometry.size.width, height: 180, alignment: .center)
                                    } else {
                                        // Big thumbnail view by default
                                        VideoFromSearchView(video: convertResult, videoThumbnailData: video.thumbnail, channelAvatarData: video.channel?.thumbnail)
                                            .frame(width: geometry.size.width, height: geometry.size.width * 9/16 + 90, alignment: .center)
                                    }
                                }
                                .listRowSeparator(.hidden)
                            })
                        }
    
                        if VPM.video != nil {
                            Color.clear
                                .frame(height: 50)
                        }
                    }
                }
#if os(macOS)
                .searchable(text: $search, placement: .toolbar)
#else
                .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always))
#endif
                .autocorrectionDisabled(true)
                .navigationTitle("Downloads")
                .customNavigationTitleWithRightIcon {
                    ShowSettingsButtonView()
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }
}
