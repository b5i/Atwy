//
//  NowPlayingBarView.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 05.05.23.
//  Copyright © 2023-2026 Antoine Bollengier. All rights reserved.
//  

import SwiftUI
import AVKit

struct NowPlayingBarView: View {
    static let height: CGFloat = 70
    
    let videoItem: YTAVPlayerItem
    let sheetAnimation: Namespace.ID
    @Binding var isSheetPresented: Bool
    var isSettingsSheetPresented: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    @ObservedProperty(PersistenceModel.shared, \.currentData, \.$currentData) private var PMcurrentData
    var body: some View {
        let isFavorite: Bool = PMcurrentData.favoriteVideoIds.contains(where: {$0 == videoItem.videoId})
        
        let downloadLocation: URL? = PMcurrentData.downloadedVideoIds.first(where: {$0.videoId == videoItem.videoId})?.storageLocation
        ZStack {
            Rectangle()
                .fill(.ultraThickMaterial)
                .foregroundColor(.clear.opacity(0.2))
                .overlay {
                    HStack {
                        VStack {
                            if !isSettingsSheetPresented {
                                VideoPlayer(player: VideoPlayerModel.shared.player)
                                    .frame(height: Self.height)
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
                            } else if let thumbnail = videoItem.video.thumbnails.first {
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
                            if let currentVideoTitle = videoItem.video.title {
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
                                VideoPlayerModel.shared.deleteCurrentVideo()
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
                                VideoPlayerModel.shared.deleteCurrentVideo()
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
        .frame(height: Self.height)
        .contextMenu {
            VideoContextMenuView(videoWithData: videoItem.video.withData(.init(allowChannelLinking: false, thumbnailData: videoItem.videoThumbnailData)), isFavorite: isFavorite, isDownloaded: downloadLocation != nil)
        } preview: {
            VideoView(videoWithData: videoItem.video.withData(.init(allowChannelLinking: false)))
                .padding(.horizontal)
                .frame(width: UIScreen.main.bounds.width * 0.85, height: 160)
        }
        .offset(y: -49)
        .onTapGesture {
            withAnimation {
                isSheetPresented = true
            }
        }
    }
}
