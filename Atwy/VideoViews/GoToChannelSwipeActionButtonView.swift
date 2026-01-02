//
//  GoToChannelSwipeActionButtonView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 19.02.23.
//  Copyright © 2023-2026 Antoine Bollengier. All rights reserved.
//

import SwiftUI
import YouTubeKit

struct GoToChannelSwipeActionButtonView: View {
    @State private var channel: YTLittleChannelInfos
    var body: some View {
        ZStack {
            Rectangle()
                .tint(.cyan)
            Image(systemName: "person.crop.rectangle")
                .tint(.white)
        }
        .tint(.cyan)
        .routeTo(.channelDetails(channel: channel))
    }
}
