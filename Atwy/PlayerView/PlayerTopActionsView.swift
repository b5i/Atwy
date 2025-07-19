//
//  PlayerTopActionsView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 06.03.2025.
//  Copyright © 2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI
import YouTubeKit

struct PlayerTopActionsView: View {
    let menuShown: Bool
    @ObservedProperty(VideoPlayerModel.shared, \.currentItem, \.$currentItem) private var currentItem
    @ObservedProperty(VideoPlayerModel.shared, \.currentVideo, \.$currentVideo) private var video: YTVideoWithData?
    
    @ObservedObject private var NRM = NetworkReachabilityModel.shared
    @ObservedObject private var DM = DownloadersModel.shared
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                if let currentItem = currentItem {
                    VideoAppreciationView(currentItem: currentItem)
                }
                if let video = video?.video {
                    if NRM.connected {
                        PlayerQuickActionView {
                            let downloadLocation: URL? = PersistenceModel.shared.currentData.downloadedVideoIds
                                .first(where: {
                                    $0.videoId == video.videoId
                                })?.storageLocation
                            DownloadButtonView(video: video, videoThumbnailData: self.video?.data.thumbnailData, downloadURL: downloadLocation)
                                .foregroundStyle(.white)
                        } action: {}
                            .contextMenu(menuItems: {
                                if DM.downloaders[video.videoId] != nil {
                                    Button(role: .destructive) {
                                        DownloadersModel.shared.cancelDownloadFor(videoId: video.videoId)
                                    } label: {
                                        HStack {
                                            Text("Cancel Download")
                                            Image(systemName: "multiply")
                                        }
                                    }
                                }
                            })
                    }
                    
                    PlayerQuickActionView {
                        AddToFavoriteWidgetView(video: video)
                    } action: {
                        if PersistenceModel.shared.checkIfFavorite(video: video) {
                            PersistenceModel.shared.removeFromFavorites(video: video)
                        } else {
                            PersistenceModel.shared.addToFavorites(video: video, imageData: currentItem?.videoThumbnailData)
                        }
                    }
                    
                    PlayerQuickActionView {
                        Image(systemName: "square.and.arrow.up")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18)
                            .foregroundStyle(.white)
                    } action: {
                        video.showShareSheet(thumbnailData: currentItem?.videoThumbnailData)
                    }
                    
                    if NRM.connected {
                        PlayerQuickActionView {
                            Image(systemName: "shareplay")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30)
                                .foregroundStyle(.white)
                        } action: {
                            CoordinationManager.shared.prepareToPlay(video)
                        }
                    }
                }
            }
            .frame(height: !menuShown ? 80 : 0)
        }
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, length: 15)
        .padding(.vertical, 15)
        .frame(height: !menuShown ? 80 : 0)
        .mask(FadeInOutView(mode: .horizontal))
        .background {
            VariableBlurView(orientation: .topToBottom)
                .ignoresSafeArea()
        }
        .opacity(!menuShown ? 1 : 0)
        .animation(.spring(duration: 0.35), value: menuShown)
        .id(currentItem)
    }
}
