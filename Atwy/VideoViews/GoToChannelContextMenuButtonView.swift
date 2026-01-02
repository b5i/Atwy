//
//  GoToChannelContextMenuButtonView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 23.01.23.
//  Copyright © 2023-2026 Antoine Bollengier. All rights reserved.
//

import SwiftUI
import YouTubeKit

struct GoToChannelContextMenuButtonView: View {
    let channel: YTLittleChannelInfos
    var body: some View {
        HStack {
            Image(systemName: "person.crop.rectangle")
            Text("Go to channel")
        }
        .routeTo(.channelDetails(channel: channel))
    }
}
