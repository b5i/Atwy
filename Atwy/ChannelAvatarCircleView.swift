//
//  ChannelAvatarCircleView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 23.01.23.
//  Copyright © 2023-2025 Antoine Bollengier. All rights reserved.
//

import SwiftUI

struct ChannelAvatarCircleView: View {
    let avatarURL: URL?
    var body: some View {
        CachedAsyncImage(url: avatarURL) { image in
            image
                .resizable()
                .clipShape(Circle())
                .scaledToFit()
                .shadow(radius: 15)
        } placeholder: {
            RoundedThumbnailPlaceholderView()
        }
    }
}
