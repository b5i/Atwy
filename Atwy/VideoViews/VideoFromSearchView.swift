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
    var isShort: Bool = false
    let video: YTVideo
    var disableChannelNavigation: Bool = false
    var videoThumbnailData: Data? = nil
    var channelAvatarData: Data? = nil
    @ObservedObject private var PSM = PreferencesStorageModel.shared
    var body: some View {
        Button {
            if VideoPlayerModel.shared.currentItem?.videoId != video.videoId {
                VideoPlayerModel.shared.loadVideo(video: video, thumbnailData: videoThumbnailData, channelAvatarImageData: channelAvatarData)
            }
            SheetsModel.shared.showSheet(.watchVideo)
        } label: {
            if let state = PSM.propetriesState[.videoViewMode] as? PreferencesStorageModel.Properties.VideoViewModes, state == .halfThumbnail {
                    VideoView(
                        video: video,
                        disableChannelNavigation: self.disableChannelNavigation,
                        thumbnailData: videoThumbnailData,
                        isShort: isShort
                    )
            } else {
                // Big thumbnail view by default
                VideoView2(
                    video: video,
                    disableChannelNavigation: self.disableChannelNavigation,
                    thumbnailData: videoThumbnailData,
                    ownerThumbnailData: channelAvatarData,
                    isShort: isShort
                )
            }
        }
        .padding(.horizontal, 5)
    }
}
