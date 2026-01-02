//
//  ChannelIllustrationView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 23.01.23.
//  Copyright © 2023-2026 Antoine Bollengier. All rights reserved.
//

import SwiftUI

struct ChannelIllustrationView: View {
    let channelAvatarURL: URL?
    let channelBannerURL: URL?
    let channelTitle: String
    var body: some View {
        VStack {
            ChannelBannerRectangleView(channelBannerURL: channelBannerURL)
            .overlay(alignment: .center) {
                ChannelAvatarCircleView(avatarURL: channelAvatarURL)
            }
            Text(channelTitle)
                .font(.title)
                .bold()
        }
    }
}
