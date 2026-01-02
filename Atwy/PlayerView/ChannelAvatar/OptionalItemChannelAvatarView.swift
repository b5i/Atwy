//
//  OptionalItemChannelAvatarView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 18.04.2024.
//  Copyright © 2024-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation
import SwiftUI

struct OptionalItemChannelAvatarView: View {
    let makeGradient: (UIImage) -> Void
    @ObservedProperty(VideoPlayerModel.shared, \.currentItem, \.$currentItem) private var currentItem
    @ObservedProperty(VideoPlayerModel.shared, \.currentVideo, \.$currentVideo) private var currentVideo
    
    @ObservedObject private var NM = NetworkReachabilityModel.shared
    var body: some View {
        Group {
            if let currentItem = currentItem {
                ChannelAvatarView(currentItem: currentItem, makeGradient: makeGradient)
            } else if let imageData = currentVideo?.data.channelAvatarData, let uiImage = UIImage(data: imageData) {
                AvatarCircleView(image: uiImage, makeGradient: makeGradient)
            } else {
                NoAvatarCircleView(makeGradient: makeGradient)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if let currentItem = currentItem, NM.connected {
                SubscribeButtonOverlayView(currentItem: currentItem)
            }
        }
        .id(currentItem)
    }
}
