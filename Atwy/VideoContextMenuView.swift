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
                    Text("Share")
                }
                */
            } else {
                DownloadAdaptativeFormatsContextMenuView(video: video, videoThumbnailData: videoThumbnailData)
            }
        }
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

/* to be activated later
class VideoShareSource: NSObject, UIActivityItemSource {
    let videoURL: URL
    let video: YTVideo
    
    init(videoURL: URL, video: YTVideo) {
        self.videoURL = videoURL
        self.video = video
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return videoURL
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return videoURL
    }
        
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return video.title ?? ""
    }
    
    
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        return UTType.mpeg4Movie.identifier
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, thumbnailImageForActivityType activityType: UIActivity.ActivityType?, suggestedSize size: CGSize) -> UIImage? {
        guard let thumbnailURL = video.thumbnails.first?.url, let imageData = try? Data(contentsOf: thumbnailURL) else { return nil }
        return UIImage(data: imageData)
    }
    
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = video.title
        
        metadata.url = videoURL
        return metadata
    }
}
*/
