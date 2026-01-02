//
//  AddToQueueSwipeActionButtonsView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 05.02.23.
//  Copyright © 2023-2026 Antoine Bollengier. All rights reserved.
//

import SwiftUI
import YouTubeKit

struct AddToQueueSwipeActionButtonsView: View {
    let video: YTVideo
    let videoThumbnailData: Data?
    var body: some View {
        Button {
            if let videoThumbnailData = videoThumbnailData {
                VideoThumbnailsManager.main.images[video.videoId] = videoThumbnailData
            }
            PopupsModel.shared.showPopup(.playNext, data: videoThumbnailData)

            VideoPlayerModel.shared.addVideoToTopQueue(video: video)
        } label: {
            ZStack {
                Rectangle()
                    .tint(.purple)
                Image(systemName: "text.line.first.and.arrowtriangle.forward")
                    .tint(.white)
            }
        }
        .tint(.purple)
        Button {
            if let videoThumbnailData = videoThumbnailData {
                VideoThumbnailsManager.main.images[video.videoId] = videoThumbnailData
            }
            PopupsModel.shared.showPopup(.playLater, data: videoThumbnailData)
            
            VideoPlayerModel.shared.addVideoToBottomQueue(video: video)
        } label: {
            ZStack {
                Rectangle()
                    .tint(.orange)
                Image(systemName: "text.line.last.and.arrowtriangle.forward")
                    .tint(.white)
            }
        }
        .tint(.orange)
    }
}
