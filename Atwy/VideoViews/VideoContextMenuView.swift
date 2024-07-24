//
//  VideoContextMenuView.swift
//
//  Created by Antoine Bollengier (github.com/b5i) on 29.07.2023.
//  Copyright © 2023 Antoine Bollengier. All rights reserved.
//  

import SwiftUI
import YouTubeKit
import AVFoundation
import LinkPresentation

struct VideoContextMenuView: View {
    @ObservedObject private var APIM = APIKeyModel.shared
    @ObservedObject private var NRM = NetworkReachabilityModel.shared
    let videoWithData: YTVideoWithData
    let isFavorite: Bool
    let isDownloaded: Bool
    
    @State private var downloader: HLSDownloader? = nil
    var body: some View {
        Group {
            Section {
                if NRM.connected {
                    if APIKeyModel.shared.userAccount != nil && APIM.googleCookies != "" {
                        AddToPlaylistContextMenuButtonView(video: self.videoWithData.video)
                    }
                    if self.videoWithData.data.allowChannelLinking, let channel = self.videoWithData.video.channel {
                        GoToChannelContextMenuButtonView(channel: channel)
                    }
                }
                Button {
                    self.videoWithData.video.showShareSheet(thumbnailData: self.videoWithData.data.thumbnailData)
                } label: {
                    HStack {
                        Text("Share")
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            Section {
                AddToQueueContextMenuButtonView(video: self.videoWithData.video, videoThumbnailData: self.videoWithData.data.thumbnailData)
            }
            Section {
                if isFavorite {
                    DeleteFromFavoritesView(video: self.videoWithData.video)
                } else {
                    AddToFavoritesContextButtonView(
                        video: self.videoWithData.video,
                        imageData: self.videoWithData.data.thumbnailData
                    )
                }
                //            if let downloadURL = downloadURL {
                if isDownloaded {
                    RemoveDownloadContextMenuButtonView(video: self.videoWithData.video)
                    /* to be activated later
                     Button {
                     guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene, let source =  scene.keyWindow?.rootViewController else { return }
                     let asset = AVAsset(url: downloadURL)
                     let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough)
                     session?.outputFileType = .mp4
                     guard let outputURL = URL(string: "\(downloadURL.deletingLastPathComponent().path())temp_export_" + UUID().uuidString + ".mp4") else { return }
                     session?.outputURL = outputURL
                     session?.metadata = [
                     createMetdataItem(value: video.title ?? "", type: .commonIdentifierTitle),
                     createMetdataItem(value: video.title ?? "", type: .quickTimeMetadataTitle),
                     createMetdataItem(value: video.channel?.name ?? "", type: .commonIdentifierArtist),
                     createMetdataItem(value: video.channel?.name ?? "", type: .iTunesMetadataTrackSubTitle),
                     createMetdataItem(value: video.channel?.name ?? "", type: .iTunesMetadataArtist),
                     createMetdataItem(value: video.channel?.name ?? "", type: .quickTimeMetadataArtist)
                     ]
                     session?.exportAsynchronously {
                     let vc = UIActivityViewController(
                     activityItems: [VideoShareSource(videoURL: outputURL, video: video)],
                     applicationActivities: nil
                     )
                     //vc.excludedActivityTypes = [.]
                     DispatchQueue.main.async {
                     vc.popoverPresentationController?.sourceView = source.view
                     source.present(vc, animated: true)
                     }
                     }
                     } label: {
                     Text("Export")
                     }
                     */
                } else if let downloader = self.downloader {
                    CancelDownloadContextMenuView(downloader: downloader)
                } else {
                    DownloadAdaptativeFormatsContextMenuView(video: self.videoWithData.video, videoThumbnailData: self.videoWithData.data.thumbnailData)
                }
            }
            if let playlistRemovalCallback = videoWithData.data.removeFromPlaylistAvailable {
                Section {
                    RemoveVideoFromPlaylistContextMenuButtonView(removalCallBack: playlistRemovalCallback)
                }
            }
        }
        .onAppear {
            if let downloader = DownloadersModel.shared.downloaders[self.videoWithData.video.videoId] {
                self.downloader = downloader
            }
        }
        .onReceive(of: .atwyDownloadingChanged(for: self.videoWithData.video.videoId), handler: { _ in
            self.downloader = DownloadersModel.shared.downloaders[self.videoWithData.video.videoId]
        })
    }
    
    /* to be activated later
    private func createMetdataItem(value: String, type: AVMetadataIdentifier, key: AVMetadataKey? = nil) -> AVMetadataItem {
        let metadataItem = AVMutableMetadataItem()
        metadataItem.locale = NSLocale.current
        if let key = key {
            metadataItem.key = key as any NSCopying & NSObjectProtocol
        } else {
            metadataItem.identifier = type
        }
        metadataItem.value = value as NSString
        metadataItem.extendedLanguageTag = "und"
        return metadataItem
    }

    private func createArtworkItem(imageData: Data) -> AVMetadataItem {
        let artwork = AVMutableMetadataItem()
        artwork.value = UIImage(data: imageData)!.pngData() as (NSCopying & NSObjectProtocol)?
        artwork.dataType = kCMMetadataBaseDataType_PNG as String
        artwork.identifier = .commonIdentifierArtwork
        artwork.extendedLanguageTag = "und"
        return artwork
    }
     */
}
