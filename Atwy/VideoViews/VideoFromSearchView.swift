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
    @State var isShort: Bool = false
    @State var video: YTVideo
    @State var videoThumbnailData: Data?
    @State var channelAvatarData: Data?
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
                        thumbnailData: videoThumbnailData, 
                        isShort: isShort
                    )
            } else {
                // Big thumbnail view by default
                VideoView2(
                    video: video,
                    thumbnailData: videoThumbnailData,
                    ownerThumbnailData: channelAvatarData,
                    isShort: isShort
                )
            }
        }
        .padding(.horizontal, 5)
    }
}
