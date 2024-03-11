//
//  GoToChannelSwipeActionButtonView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 19.02.23.
//

import SwiftUI
import YouTubeKit

struct GoToChannelSwipeActionButtonView: View {
    @State var channel: YTLittleChannelInfos
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
