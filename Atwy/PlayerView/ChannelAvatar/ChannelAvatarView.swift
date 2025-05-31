//
//  ChannelAvatarView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 18.04.2024.
//  Copyright © 2024-2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation
import SwiftUI

struct ChannelAvatarView: View {
    let makeGradient: (UIImage) -> Void
    @ObservedModel<YTAVPlayerItem, URL?> private var avatarURL: URL?
    @ObservedProperty<YTAVPlayerItem, Data?> private var avatarData: Data?
    
    init(currentItem: YTAVPlayerItem, makeGradient: @escaping (UIImage) -> Void) {
        self._avatarURL = ObservedModel(currentItem, { item in
            return ((currentItem.streamingInfos.channel?.thumbnails.maxFor(2) ?? currentItem.moreVideoInfos?.channel?.thumbnails.maxFor(2)) ?? currentItem.video.channel?.thumbnails.maxFor(2))?.url
        })
        
        self._avatarData = ObservedProperty(currentItem, \.channelAvatarImageData, \.$channelAvatarImageData)
        self.makeGradient = makeGradient
    }
    
    var body: some View {
        ZStack {
            if let avatarURL = avatarURL {
                CachedAsyncImage(url: avatarURL) { _, imageData in
                    if !imageData.isEmpty, let uiImage = UIImage(data: imageData) {
                        AvatarCircleView(image: uiImage, makeGradient: makeGradient)
                    } else if let imageData = avatarData, let image = UIImage(data: imageData) {
                        AvatarCircleView(image: image, makeGradient: makeGradient)
                    } else {
                        NoAvatarCircleView(makeGradient: makeGradient)
                    }
                }
            } else if let imageData = avatarData, let image = UIImage(data: imageData) {
                AvatarCircleView(image: image, makeGradient: makeGradient)
            } else {
                NoAvatarCircleView(makeGradient: makeGradient)
            }
        }
    }
}
