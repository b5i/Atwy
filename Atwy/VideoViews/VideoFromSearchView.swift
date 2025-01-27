//
//  VideoFromSearchView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 27.12.22.
//

import SwiftUI
import CoreData
import SwipeActions
import YouTubeKit

struct VideoFromSearchView: View {
    @Environment(\.colorScheme) private var colorScheme
    let videoWithData: YTVideoWithData
    @ObservedObject private var PSM = PreferencesStorageModel.shared
    var body: some View {
        Button {
            if VideoPlayerModel.shared.currentItem?.videoId != videoWithData.video.videoId {
                VideoPlayerModel.shared.loadVideo(video: videoWithData.video, thumbnailData: self.videoWithData.data.thumbnailData, channelAvatarImageData: self.videoWithData.data.channelAvatarData)
            }
            SheetsModel.shared.showSheet(.watchVideo)
        } label: {
            if PSM.videoViewMode == .halfThumbnail || self.videoWithData.data.videoViewMode == .halfThumbnail {
                VideoView(videoWithData: videoWithData)
            } else {
                // Big thumbnail view by default
                VideoView2(videoWithData: videoWithData)
            }
        }
        .padding(.horizontal, 5)
    }
}
