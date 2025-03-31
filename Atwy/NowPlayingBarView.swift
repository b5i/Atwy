//
//  NowPlayingBarView.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 05.05.23.
//  Copyright © 2023-2025 Antoine Bollengier. All rights reserved.
//  

import SwiftUI
import AVKit

struct NowPlayingBarView: View {
    let sheetAnimation: Namespace.ID
    @Binding var isSheetPresented: Bool
    var isSettingsSheetPresented: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var VPM = VideoPlayerModel.shared
    @ObservedObject private var PM = PersistenceModel.shared
    var body: some View {
        let isFavorite: Bool = {
            guard let videoId = VPM.currentItem?.videoId else { return false }
            return PM.currentData.favoriteVideoIds.contains(where: {$0 == videoId})
        }()
        
        let downloadLocation: URL? = {
            guard let videoId = VPM.currentItem?.videoId else { return nil }
            return PM.currentData.downloadedVideoIds.first(where: {$0.videoId == videoId})?.storageLocation
        }()
        ZStack {
            Rectangle()
                .fill(.ultraThickMaterial)
                .foregroundColor(.clear.opacity(0.2))
                .overlay {
                    HStack {
                        VStack {
                            if !isSettingsSheetPresented {
                                VideoPlayer(player: VPM.player)
                                    .frame(height: 70)
                                    .onAppear {
#if os(macOS)
                                        if NSApplication.shared.isActive {
                                            withAnimation {
                                                isSheetPresented = true
                                            }
                                        }
#else
                                        if UIApplication.shared.applicationState == .background {
                                            withAnimation {
                                                isSheetPresented = true
                                            }
                                        }
#endif
                                    }
                                    .disabled(true)
                            } else if let thumbnail = VPM.currentItem?.video.thumbnails.first {
                                CachedAsyncImage(url: thumbnail.url, content: { image, _ in
                                    switch image {
                                    case .success(let image):
                                        image
                                            .resizable()
                                    default:
                                        Rectangle()
                                            .foregroundColor(colorScheme.backgroundColor)
                                    }
                                })
                            }
                        }
                        .frame(width: 114, height: 64)
                        .frame(alignment: .leading)
                        .matchedGeometryEffect(id: "VIDEO", in: sheetAnimation)
                        Spacer()
                        VStack {
                            if let currentVideoTitle = VPM.currentItem?.video.title {
                                Text(currentVideoTitle)
                                    .truncationMode(.tail)
                                    .foregroundColor(colorScheme.textColor)
                            } else {
                                Text("No title")
                                    .truncationMode(.tail)
                                    .foregroundColor(colorScheme.textColor)
                            }
                        }
                        .padding(.horizontal)
                        Spacer()
                        //                            }
                        Button {
                            withAnimation {
                                VPM.deleteCurrentVideo()
                            }
                        } label: {
                            Image(systemName: "multiply")
                                .resizable()
                                .foregroundColor(colorScheme.textColor)
                                .scaledToFit()
                        }
                        .frame(width: 15, height: 15)
                        .padding(.trailing)
                        .contentShape(Rectangle())
                        .tappablePadding(.init(top: 10, leading: 10, bottom: 10, trailing: 10), onTap: {
                            withAnimation {
                                VPM.deleteCurrentVideo()
                            }
                        })
                    }
                }
                .matchedGeometryEffect(id: "BGVIEW", in: sheetAnimation)
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(.gray.opacity(0.1))
                .frame(height: 1)
        }
        .frame(height: 70)
        .contextMenu {
            if let video = VPM.currentItem?.video {
                VideoContextMenuView(videoWithData: video.withData(.init(allowChannelLinking: false, thumbnailData: VPM.currentItem?.videoThumbnailData)), isFavorite: isFavorite, isDownloaded: downloadLocation != nil)
            }
        } preview: {
            if let video = VPM.currentItem?.video {
                VideoView(videoWithData: video.withData(.init(allowChannelLinking: false)))
            }
        }
        .offset(y: -49)
        .onTapGesture {
            withAnimation {
                isSheetPresented = true
            }
        }
    }
}
