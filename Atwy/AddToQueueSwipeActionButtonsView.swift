//
//  AddToQueueSwipeActionButtonsView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 05.02.23.
//

import SwiftUI
import YouTubeKit

struct AddToQueueSwipeActionButtonsView: View {
    let video: YTVideo
    let videoThumbnailData: Data?
    @ObservedObject var PQM = PlayingQueueModel.shared
    var body: some View {
        Button {
            if let videoThumbnailData = videoThumbnailData {
                VideoThumbnailsManager.main.images[video.videoId] = videoThumbnailData
            }
            PQM.queue.insert(video, at: 0)
            PQM.indexQueue()
            PopupsModel.shared.showPopup(.playNext, data: videoThumbnailData)
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
            PQM.queue.append(video)
            PQM.indexQueue()
            PopupsModel.shared.showPopup(.playLater, data: videoThumbnailData)
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
