//
//  ChannelView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 27.12.22.
//  Copyright © 2022-2025 Antoine Bollengier. All rights reserved.
//

import SwiftUI
import YouTubeKit

struct ChannelView: View {
    @Environment(\.colorScheme) private var colorScheme
    let channel: YTChannel
    var body: some View {
        GeometryReader { geometry in
            HStack {
                HStack {
                    CachedAsyncImage(url: channel.thumbnails.last?.url) { image in
                        image
                            .resizable()
                            .clipShape(Circle())
                            .shadow(radius: 3)
                            .padding(.trailing)
                    } placeholder: {
                        RoundedThumbnailPlaceholderView()
                    }
                    .frame(width: 125)
                    // Add badges
                }
                .frame(width: geometry.size.width * 0.5, height: 125, alignment: .center)
                VStack {
                    VStack {
                        Text(channel.name ?? "")
                    }
                    .foregroundColor(colorScheme.textColor)
                    .truncationMode(.tail)
                    .frame(height: 125)
                    Divider()
                    Text(channel.subscriberCount ?? "")
                        .foregroundColor(colorScheme.textColor)
                        .font(.footnote)
                        .opacity(0.5)
                        .bold()
                }
                .frame(width: geometry.size.width * 0.475, height: geometry.size.height)
                Spacer()
            }
            .routeTo(.channelDetails(channel: .init(channelId: channel.channelId, name: channel.name, thumbnails: channel.thumbnails)))
        }
        .contextMenu {
            Button(action: {
                self.channel.showShareSheet()
            }, label: {
                Text("Share")
                Image(systemName: "square.and.arrow.up")
                    .resizable()
                    .scaledToFit()
            })
        }
    }
}
