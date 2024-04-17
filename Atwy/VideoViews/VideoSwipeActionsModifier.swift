//
//  VideoSwipeActionsModifier.swift
//  Atwy
//
//  Created by Antoine Bollengier on 17.04.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI
import SwipeActions
import YouTubeKit

extension View {
    func videoSwipeActions(video: YTVideo, thumbnailData: Data?, isConnectedToNetwork: Bool, disableChannelNavigation: Bool, isConnectedToGoogle: Bool) -> some View {
        self
            .swipeAction(leadingActions: { context in
                SwipeAction(
                    action: {
                        if let videoThumbnailData = thumbnailData {
                            VideoThumbnailsManager.main.images[video.videoId] = videoThumbnailData
                        }
                        VideoPlayerModel.shared.addVideoToTopQueue(video: video)
                        PopupsModel.shared.showPopup(.playNext, data: thumbnailData)
                        context.state.wrappedValue = .closed
                    },
                    label: { _ in
                        Image(systemName: "text.line.first.and.arrowtriangle.forward")
                            .foregroundStyle(.white)
                    },
                    background: { _ in
                        Rectangle()
                            .fill(.purple)
                    }
                )
                .allowSwipeToTrigger(true)
                SwipeAction(
                    action: {
                        if let videoThumbnailData = thumbnailData {
                            VideoThumbnailsManager.main.images[video.videoId] = videoThumbnailData
                        }
                        VideoPlayerModel.shared.addVideoToBottomQueue(video: video)
                        PopupsModel.shared.showPopup(.playLater, data: thumbnailData)
                        context.state.wrappedValue = .closed
                    },
                    label: { _ in
                        Image(systemName: "text.line.last.and.arrowtriangle.forward")
                            .foregroundStyle(.white)
                    },
                    background: { _ in
                        Rectangle()
                            .fill(.orange)
                    }
                )
            }, trailingActions: { context in
                if isConnectedToNetwork {
                    if !disableChannelNavigation, let channel = video.channel {
                        SwipeAction(
                            action: {},
                            label: { _ in
                                Image(systemName: "person.crop.rectangle")
                                    .foregroundStyle(.white)
                            },
                            background: { _ in
                                Rectangle()
                                    .fill(.cyan)
                                    .routeTo(.channelDetails(channel: channel))
                                    .onDisappear {
                                        context.state.wrappedValue = .closed
                                    }
                            }
                        )
                    }
                    if isConnectedToGoogle {
                        SwipeAction(
                            action: {
                                SheetsModel.shared.showSheet(.addToPlaylist, data: video)
                                context.state.wrappedValue = .closed
                            },
                            label: { _ in
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(.white)
                            },
                            background: { _ in
                                Rectangle()
                                    .fill(.blue)
                            }
                        )
                        .allowSwipeToTrigger()
                    }
                }
            }, minimumSwipeDistance: 50)
    }
}
