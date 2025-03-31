//
//  RemoveDownloadContextMenuButtonView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 24.01.23.
//  Copyright © 2023-2025 Antoine Bollengier. All rights reserved.
//

import SwiftUI
import CoreData
import YouTubeKit

struct RemoveDownloadContextMenuButtonView: View {
    @Environment(\.managedObjectContext) private var context
    let video: YTVideo
    var body: some View {
        Button(role: .destructive) {
            Task {
                if VideoPlayerModel.shared.currentItem?.videoId == video.videoId {
                    VideoPlayerModel.shared.deleteCurrentVideo()
                }
                PersistenceModel.shared.removeDownloadFromCoreData(videoId: video.videoId)
                PopupsModel.shared.showPopup(.deletedDownload)
            }
        } label: {
            HStack {
                Text("Remove Download")
                Image(systemName: "trash")
            }
            .tint(.red)
        }
    }
}
