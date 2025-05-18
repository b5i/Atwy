//
//  OptionalItemChannelAvatarView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 18.04.2024.
//  Copyright © 2024-2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation
import SwiftUI

struct OptionalItemChannelAvatarView: View {
    let makeGradient: (UIImage) -> Void
    @ObservedObject private var VPM = VideoPlayerModel.shared
    @ObservedObject private var NM = NetworkReachabilityModel.shared
    var body: some View {
        Group {
            if let currentItem = VPM.currentItem {
                ChannelAvatarView(makeGradient: makeGradient, currentItem: currentItem)
            } else if let imageData = VPM.loadingVideo?.data.channelAvatarData, let uiImage = UIImage(data: imageData) {
                AvatarCircleView(image: uiImage, makeGradient: makeGradient)
            } else {
                NoAvatarCircleView(makeGradient: makeGradient)
            }
        }
        .overlay(alignment: .bottomTrailing, content: {
            if let currentItem = VPM.currentItem, NM.connected {
                SubscribeButtonOverlayView(currentItem: currentItem)
            }
        })
    }
}
