//
//  YouTubeBasePlaylistView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 10.02.23.
//

import SwiftUI
import YouTubeKit

struct YouTubeBasePlaylistView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State var playlist: YTPlaylist?
    var body: some View {
        GeometryReader { geometry in
            VStack {
                if let playlist = playlist {
                    VStack(spacing: 0) {
                        HStack {
                            Text(playlist.title ?? "")
                                .font(.title2)
                                .padding()
                                .foregroundColor(colorScheme.textColor)
                            Spacer()
                        }
                        HStack {
                            ZStack {
                                ForEach(Array(playlist.frontVideos.dropLast((playlist.frontVideos.count > 3) ? playlist.frontVideos.count - 4 : 0).reversed().enumerated()), id: \.offset) { item in
                                    let scaleLevel: Double = Double(item.offset) * 0.05 + 0.85
                                    let opactityLevel: Double = Double(item.offset) * 0.1 + 0.70
                                    VideoView.ImageOfVideoView(video: item.element, hqImage: true)
                                        .frame(width: geometry.size.width * 0.5, height: geometry.size.height)
                                        .padding(.trailing, CGFloat(item.offset) * 50)
                                        .scaleEffect(scaleLevel)
                                        .shadow(radius: 3)
                                        .overlay {
                                            Rectangle()
                                                .foregroundColor(colorScheme.backgroundColor)
                                                .opacity(1 - opactityLevel)
                                        }
                                }
                                VStack {
                                    if let elementsCount = playlist.videoCount {
                                        Text(elementsCount)
                                            .font(.title2)
                                            .foregroundColor(colorScheme.textColor)
                                        Image(systemName: "play.rectangle")
                                            .resizable()
                                            .scaledToFit()
                                            .font(.title2)
                                            .foregroundColor(colorScheme.textColor)
                                    }
                                }
                                .frame(width: 60, height: 60)
                                .padding(.leading, geometry.size.width * 0.8)
                            }
                        }
                    }
                    .routeTo(.playlistDetails(playlist: playlist))
                }
            }
        }
    }
}
