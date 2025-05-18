//
//  VideoFromSearchView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 27.12.22.
//  Copyright © 2022-2025 Antoine Bollengier. All rights reserved.
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
                VideoPlayerModel.shared.loadVideo(video: videoWithData)
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
