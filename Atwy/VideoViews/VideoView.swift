//
//  VideoView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 25.11.22.
//  Copyright © 2022-2025 Antoine Bollengier. All rights reserved.
//

import SwiftUI
import CoreData
import SwipeActions
import YouTubeKit

struct VideoView: View {
    @Environment(\.colorScheme) private var colorScheme
    let videoWithData: YTVideoWithData
    @ObservedObject private var APIM = APIKeyModel.shared
    @ObservedObject private var NRM = NetworkReachabilityModel.shared
    @ObservedObject private var PM = PersistenceModel.shared
    var body: some View {
        let video = videoWithData.video
        let isFavorite: Bool = {
            return PM.currentData.favoriteVideoIds.contains(where: {$0 == video.videoId})
        }()
        
        let downloadLocation: URL? = {
            return PM.currentData.downloadedVideoIds.first(where: {$0.videoId == video.videoId})?.storageLocation
        }()
        
        GeometryReader { geometry in
            HStack(spacing: 3) {
                VStack {
                    ImageOfVideoView(videoWithData: self.videoWithData)
                        .overlay(alignment: .bottomTrailing, content: {
                            if let timeLenght = video.timeLength {
                                if timeLenght == "live" {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 5)
                                            .foregroundColor(.red)
                                        HStack {
                                            Image(systemName: "antenna.radiowaves.left.and.right")
                                            Text("En Direct")
                                        }
                                        .bold()
                                        .foregroundColor(.white)
                                        .font(.system(size: 14))
                                    }
                                    .frame(width: 100, height: 20)
                                    .padding(3)
                                } else {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 5)
                                            .opacity(0.9)
                                            .foregroundColor(.black)
                                        Text(timeLenght)
                                            .bold()
                                            .foregroundColor(.white)
                                            .font(.system(size: 14))
                                    }
                                    .frame(width: CGFloat(timeLenght.count) * 10, height: 20)
                                    .padding(3)
                                }
                            }
                        })
                        .frame(width: geometry.size.width * 0.52, height: geometry.size.height * 0.7)
                        .shadow(radius: 3)
                    HStack {
                        VStack {
                            if let viewCount = video.viewCount {
                                Text(viewCount)
                                    .foregroundColor(colorScheme.textColor)
                                    .font(.footnote)
                                    .opacity(0.5)
                                    .padding(.top, (video.timePosted != nil) ? -2 : -15)
                                if video.timePosted != nil {
                                    Divider()
                                        .padding(.leading)
                                        .padding(.top, -6)
                                }
                            }
                            if let timePosted = video.timePosted {
                                Text(timePosted)
                                    .foregroundColor(colorScheme.textColor)
                                    .font(.footnote)
                                    .opacity(0.5)
                                    .padding(.top, -12)
                            }
                        }
                        if video.timeLength != "live" {
                            if video.timePosted != nil || video.viewCount != nil {
                                Divider()
                            }
                            DownloadButtonView(video: video, videoThumbnailData: self.videoWithData.data.thumbnailData, downloadURL: downloadLocation)
                                .foregroundStyle(colorScheme.textColor)
                        }
                    }
                    .frame(height: geometry.size.height * 0.15)
                    .padding(.top, 1)
                }
                .frame(width: geometry.size.width * 0.52, height: geometry.size.height)
                VStack {
                    Text(video.title ?? "")
                        .foregroundColor(colorScheme.textColor)
                        .truncationMode(.tail)
                        .frame(height: geometry.size.height * 0.7)
                    if let channelName = video.channel?.name {
                        Divider()
                        Text(channelName)
                            .foregroundColor(colorScheme.textColor)
                            .bold()
                            .font(.footnote)
                            .opacity(0.5)
                    }
                }
                .frame(width: geometry.size.width * 0.475, height: geometry.size.height)
            }
            .contextMenu {
                VideoContextMenuView(videoWithData: self.videoWithData, isFavorite: isFavorite, isDownloaded: downloadLocation != nil)
            }
            .videoSwipeActions(video: video, thumbnailData: self.videoWithData.data.thumbnailData, isConnectedToNetwork: self.NRM.connected, disableChannelNavigation: !self.videoWithData.data.allowChannelLinking, isConnectedToGoogle: APIKeyModel.shared.userAccount != nil && APIM.googleCookies != "")
        }
    }
    
    struct ImageOfVideoView: View {
        @Environment(\.colorScheme) private var colorScheme
        let videoWithData: YTVideoWithData
        var hqImage: Bool = false
        var body: some View {
            ZStack {
                if let thumbnailData = self.videoWithData.data.thumbnailData {
#if os(macOS)
                    if let image = NSImage(data: thumbnailData) {
                        Image(nsImage: image)
                            .scaledToFit()
                            .resizable()
                    } else {
                        Rectangle()
                            .foregroundColor(.gray)
                    }
#else
                    if let image = UIImage(data: thumbnailData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Rectangle()
                            .foregroundColor(.gray)
                    }
#endif
                } else if hqImage, let thumbnail = self.videoWithData.video.thumbnails.last, (thumbnail.width ?? 0) >= 480 {
                    CachedAsyncImage(url: thumbnail.url) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        RectangularThumbnailPlaceholderView()
                    }
                } else if hqImage, let thumbnailURL = URL(string: "https://i.ytimg.com/vi/\(self.videoWithData.video.videoId)/hqdefault.jpg") {
                    CachedAsyncImage(url: thumbnailURL) { image in
                        if let croppedImage = cropImage(image) {
                            croppedImage
                                .resizable()
                                .scaledToFill()
                                .aspectRatio(16/9, contentMode: .fit)
                        } else {
                            RectangularThumbnailPlaceholderView()
                        }
                    } placeholder: {
                        RectangularThumbnailPlaceholderView()
                    }
                } else if let url = self.videoWithData.video.thumbnails.last?.url {
                    CachedAsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        RectangularThumbnailPlaceholderView()
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        
        // Inspired from https://developer.apple.com/documentation/coregraphics/cgimage/1454683-cropping
        @MainActor private func cropImage(_ inputImage: Image) -> Image? {
            // Extract UIImage from Image
            guard let uiImage = ImageRenderer(content: inputImage).uiImage else { return nil }
            let portionToCut = (uiImage.size.height - uiImage.size.width * 9/16) / 2
            
            // Scale cropRect to handle images larger than shown-on-screen size
            let cropZone = CGRect(x: 0,
                                  y: portionToCut,
                                  width: uiImage.size.width,
                                  height: uiImage.size.height - portionToCut * 2)
            
            // Perform cropping in Core Graphics
            guard let cutImageRef: CGImage = uiImage.cgImage?.cropping(to: cropZone)
            else {
                return nil
            }
            
            // Return image to UIImage
            let croppedImage: UIImage = UIImage(cgImage: cutImageRef)
            return Image(uiImage: croppedImage)
        }
    }
}

struct VideoView2: View {
    @Environment(\.colorScheme) private var colorScheme
    let videoWithData: YTVideoWithData
    @ObservedObject private var APIM = APIKeyModel.shared
    @ObservedObject private var NRM = NetworkReachabilityModel.shared
    @ObservedObject private var PM = PersistenceModel.shared
    var body: some View {
        let video = videoWithData.video
        
        let isFavorite: Bool = {
            return PM.currentData.favoriteVideoIds.contains(where: {$0 == video.videoId})
        }()
        
        let downloadLocation: URL? = {
            return PM.currentData.downloadedVideoIds.first(where: {$0.videoId == video.videoId})?.storageLocation
        }()
        
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                VideoView.ImageOfVideoView(videoWithData: self.videoWithData, hqImage: true)
                    .overlay(alignment: .bottomTrailing, content: {
                        if let timeLenght = video.timeLength {
                            if timeLenght == "live" {
                                ZStack {
                                    Rectangle()
                                        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 10, bottomTrailingRadius: 10))
                                        .foregroundStyle(.red)
                                    HStack {
                                        Image(systemName: "antenna.radiowaves.left.and.right")
                                        Text("En Direct")
                                    }
                                    .bold()
                                    .foregroundStyle(.white)
                                    .font(.system(size: 14))
                                    .frame(alignment: .center)
                                }
                                .frame(width: 105, height: 25)
                            } else {
                                ZStack {
                                    Rectangle()
                                        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 10, bottomTrailingRadius: 10))
                                        .foregroundStyle(.black)
                                    Text(timeLenght)
                                        .bold()
                                        .foregroundStyle(.white)
                                        .font(.system(size: 14))
                                        .frame(alignment: .center)
                                }
                                .frame(width: CGFloat(timeLenght.count) * 10 + 5, height: 25)
                            }
                        }
                    })
                    .padding(.horizontal, 5)
                    .frame(width: geometry.size.width)
//                    .background(Color(uiColor: .init(red: 10/255, green: 10/255, blue: 10/255, alpha: 1)))
                HStack(spacing: 0) {
                    if let channel = video.channel {
                        Group {
                            if let ownerThumbnailData = videoWithData.data.channelAvatarData, let image = UIImage(data: ownerThumbnailData) {
                                VStack {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: geometry.size.width * 0.11)
                                        .clipShape(Circle())
                                    Spacer()
                                }
                                .frame(width: geometry.size.width * 0.12, alignment: .leading)
                                .padding(.top, 3)
                            } else if let ownerThumbnailURL = video.channel?.thumbnails.last?.url {
                                VStack {
                                    CachedAsyncImage(url: ownerThumbnailURL, content: { image in
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: geometry.size.width * 0.11)
                                    }, placeholder: {
                                        RoundedThumbnailPlaceholderView()
                                    })
                                    .clipShape(Circle())
                                    Spacer()
                                }
                                .frame(width: geometry.size.width * 0.12, alignment: .leading)
                                .padding(.top, 3)
                            }
                        }
                        .routeTo(NRM.connected && self.videoWithData.data.allowChannelLinking ? .channelDetails(channel: channel) : nil)
                    }
                    VStack(alignment: .leading) {
                        Text(video.title ?? "")
                            .foregroundStyle(colorScheme.textColor)
                            .lineLimit(2)
                            .foregroundStyle(.white) // Modify
                            .font(.system(size: 16))
                            .multilineTextAlignment(.leading)
                            .truncationMode(.tail)
                        Text("\(video.channel?.name ?? "")\(video.channel?.name != nil && (video.viewCount != nil || video.timePosted != nil) ? " • " : "")\(video.viewCount != nil ? "\(video.viewCount!)" : "")\(video.timePosted != nil && video.viewCount != nil ? " • " : "")\(video.timePosted != nil ? "\(video.timePosted!)" : "")")
                            .lineLimit(2)
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.leading)
                            .truncationMode(.tail)
                            .font(.caption)
                        Spacer()
                    }
                    .padding(.leading, 10)
                    .frame(width: geometry.size.width * 0.75, alignment: .leading)
                    Spacer()
                    VStack {
                        if video.timeLength != "live" {
                            DownloadButtonView(video: video, videoThumbnailData: self.videoWithData.data.thumbnailData, downloadURL: downloadLocation)
                                .foregroundStyle(colorScheme.textColor)
                        }
                        /* to be reinstated later
                        Menu {
                            VideoContextMenuView(video: video, videoThumbnailData: thumbnailData, isFavorite: isFavorite, isDownloaded: (downloadLocation != nil))
                        } label: {
                            Image(systemName: "ellipsis")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .foregroundStyle(colorScheme.textColor)
                                .contentShape(Rectangle())
                                .padding(.top, 10)
                        }
                        .frame(width: 20, height: 20)
                         */
                        AddToFavoritesButtonView(video: video, imageData: self.videoWithData.data.thumbnailData)
                            .foregroundStyle(colorScheme.textColor)
                        Spacer()
                    }
                    .frame(alignment: .top)
                    .padding(.trailing, 5)
                    if !(video.channel?.thumbnails.isEmpty ?? true) && self.videoWithData.data.channelAvatarData != nil {
                        Spacer()
                    }
                }
                .padding(.horizontal, 5)
                .padding(.top, 10)
                .frame(width: geometry.size.width, height: 90)
                Spacer()
            }
            .background(colorScheme.backgroundColor)
            .contextMenu {
                VideoContextMenuView(videoWithData: self.videoWithData, isFavorite: isFavorite, isDownloaded: (downloadLocation != nil))
            }
//            .contextMenuWrapper(menuItems: [
//                UIDeferredMenuElement({ result in
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
//                        result([UIAction(title: "+", handler: {_ in})])
//                    })
//                })
//            ], previewProvider: {
//                VideoView2(video: video, thumbnailData: thumbnailData, ownerThumbnailData: ownerThumbnailData)
//                    .frame(width: geometry.size.width, height: geometry.size.height)
//            })
            .videoSwipeActions(video: video, thumbnailData: self.videoWithData.data.thumbnailData, isConnectedToNetwork: self.NRM.connected, disableChannelNavigation: !self.videoWithData.data.allowChannelLinking, isConnectedToGoogle: APIKeyModel.shared.userAccount != nil && APIM.googleCookies != "")
        }
    }
}
