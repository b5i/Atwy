//
//  RemoveDownloadContextMenuButtonView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 24.01.23.
//

import SwiftUI
import CoreData
import YouTubeKit

struct RemoveDownloadContextMenuButtonView: View {
    @Environment(\.managedObjectContext) private var context
    @State var video: YTVideo
    var body: some View {
        Button(role: .destructive) {
            Task {
                if VideoPlayerModel.shared.video?.videoId == video.videoId {
                    VideoPlayerModel.shared.deleteCurrentVideo()
                }
                PersistenceModel.shared.removeDownloadFromCoreData(videoId: video.videoId)
                downloads.removeAll(where: {$0.video?.videoId == video.videoId})
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
