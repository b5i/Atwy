//
//  VideoContextMenuView.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 29.07.2023.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import SwiftUI
import YouTubeKit

struct VideoContextMenuView: View {
    @ObservedObject private var APIM = APIKeyModel.shared
    @ObservedObject private var NRM = NetworkReachabilityModel.shared
    @State var video: YTVideo
    @State var videoThumbnailData: Data?
    @Binding var isFavorite: Bool
    @Binding var downloadURL: URL? // The two are bindings to get refreshed as soon as their values are modified in the parent view
    var body: some View {
        Group {
            if NRM.connected {
                if APIKeyModel.shared.userAccount != nil && APIM.googleCookies != "" {
                    AddToPlaylistContextMenuButtonView(video: video)
                }
                if let channel = video.channel {
                    GoToChannelContextMenuButtonView(channel: channel)
                }
            }
            AddToQueueContextMenuButtonView(video: video, videoThumbnailData: videoThumbnailData)
            if isFavorite {
                DeleteFromFavoritesView(video: video)
            } else {
                AddToFavoritesContextButtonView(
                    video: video,
                    imageData: videoThumbnailData
                )
            }
//            if let downloadURL = downloadURL {
            if downloadURL != nil {
                RemoveDownloadContextMenuButtonView(video: video)
//                Button {
//                    guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene, let source =  scene.keyWindow?.rootViewController else { return }
//                    let vc = UIActivityViewController(
//                        activityItems: [FileManager.default.contents(atPath: downloadURL.absoluteString)],
//                        applicationActivities: nil
//                    )
//                    //vc.excludedActivityTypes = [.]
//                    vc.popoverPresentationController?.sourceView = source.view
//                    source.present(vc, animated: true)
//                } label: {
//                    Text("Share")
//                }
            } else {
                // DownloadAdaptativeFormatsContextMenuView(video: video, videoThumbnailData: videoThumbnailData)
                // Not enabled for the moment
            }
        }
    }
}
