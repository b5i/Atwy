//
//  PlaylistView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 22.01.23.
//

import SwiftUI
import YouTubeKit

struct PlaylistView: View {
    @Environment(\.colorScheme) private var colorScheme
    let playlist: YTPlaylist
    var body: some View {
        GeometryReader { geometry in
            HStack {
                VStack {
                    ImageOfPlaylistView(playlist: playlist)
                        .frame(width: geometry.size.width * 0.52, height: geometry.size.width * 0.52 * 9/16)
                        .shadow(radius: 3)
                    VStack {
                        if let videoCount = playlist.videoCount {
                            Text(videoCount)
                                .foregroundColor(colorScheme.textColor)
                                .font((playlist.timePosted != nil) ? .system(size: 10) : .footnote)
                                .bold((playlist.timePosted != nil))
                                .opacity(0.5)
                            if playlist.timePosted != nil {
                                Divider()
                                    .frame(height: 16)
                                    .padding(.top, -10)
                            }
                            if let timePosted = playlist.timePosted {
                                Text(timePosted)
                                    .foregroundColor(colorScheme.textColor)
                                    .font(.system(size: 10))
                                    .bold()
                                    .opacity(0.5)
                                    .padding(.top, -12)
                            }
                        }
                    }
                }
                .frame(width: geometry.size.width * 0.52, height: geometry.size.height)
                VStack {
                    VStack {
                        Text(playlist.title ?? "")
                    }
                    .foregroundColor(colorScheme.textColor)
                    .truncationMode(.tail)
                    .frame(height: geometry.size.height * 0.7)
                    if let channelName = playlist.channel?.name {
                        Divider()
                        Text(channelName)
                            .foregroundColor(colorScheme.textColor)
                            .bold()
                            .font(.footnote)
                            .opacity(0.5)
                    }
                }
                .frame(width: geometry.size.width * 0.475, height: geometry.size.height)
            }
            .contextMenu {
                if let channel = playlist.channel {
                    GoToChannelContextMenuButtonView(channel: channel)
                }
                Button(action: {
                    self.playlist.showShareSheet()
                }, label: {
                    Text("Share")
                    Image(systemName: "square.and.arrow.up")
                        .resizable()
                        .scaledToFit()
                })
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .routeTo(.playlistDetails(playlist: playlist))
        }
    }
    
    struct ImageOfPlaylistView: View {
        @Environment(\.colorScheme) private var colorScheme
        let playlist: YTPlaylist
        var body: some View {
            ZStack {
                if !playlist.thumbnails.isEmpty, let url = playlist.thumbnails.last?.url {
                    CachedAsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        RectangularThumbnailPlaceholderView()
                    }
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundStyle(EllipticalGradient(colors: [colorScheme.textColor, .gray, colorScheme.textColor]))
                            .aspectRatio(16/9, contentMode: .fit)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
