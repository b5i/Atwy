//
//  DownloadVideoButtonView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 23.04.23.
//

import SwiftUI
import YouTubeKit

struct DownloadVideoButtonView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State var video: YTVideo
    @State var isShort: Bool = false
    @State var videoThumbnailData: Data?
    @StateObject var downloader: HLSDownloader
    var body: some View {
        Button {
            downloader.video = video
            downloader.isShort = isShort
            downloader.state.thumbnailData = videoThumbnailData
            DownloadCoordinatorManagerModel.shared.appendDownloader(downloader: downloader)
        } label: {
            Image(systemName: "arrow.down")
                .frame(width: 25, height: 25)
                .padding()
        }
    }
}
