//
//  ChannelView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 27.12.22.
//

import SwiftUI
import YouTubeKit

struct ChannelView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State var channel: YTChannel
    var body: some View {
        NavigationLink(destination: ChannelDetailsView(channel: .init(channelId: channel.channelId, name: channel.name, thumbnails: channel.thumbnails))) {
            HStack {
                HStack {
                    CachedAsyncImage(url: channel.thumbnails.last?.url) { image in
                            image
                                .resizable()
                                .clipShape(Circle())
                                .frame(width: 125)
                                .shadow(radius: 3)
                                .padding(.trailing)
                        } placeholder: {
                            ZStack {
                                Circle()
                                    .foregroundColor(.black)
                                ProgressView()
                            }
                            .frame(width: 125)
                        }
                        // Add badges
                }
                .frame(width: 222, height: 125, alignment: .center)
                VStack {
                    VStack {
                        Text(channel.name ?? "")
                    }
                    .frame(height: 125)
                    .foregroundColor(colorScheme.textColor)
                    Divider()
                    Text(channel.subscriberCount ?? "")
                        .foregroundColor(colorScheme.textColor)
                        .font(.footnote)
                        .opacity(0.5)
                        .bold()
                }
                .frame(width: 170)
            }
        }
    }
}
