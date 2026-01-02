//
//  ChannelBannerRectangleView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 23.01.23.
//  Copyright © 2023-2026 Antoine Bollengier. All rights reserved.
//

import SwiftUI

struct ChannelBannerRectangleView: View {
    @Environment(\.colorScheme) private var colorScheme
    let channelBannerURL: URL?
    var body: some View {
        VStack {
            if channelBannerURL != nil {
                CachedAsyncImage(url: channelBannerURL) { image in
                    image
                        .resizable()
                        .opacity(0.8)
                } placeholder: {
                    ProgressView()
                }
            } else {
                Rectangle()
                    .foregroundColor(colorScheme.textColor)
            }
        }
        .aspectRatio(32/9, contentMode: .fit)
    }
}
