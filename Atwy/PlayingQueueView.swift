//
//  PlayingQueueView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 28.01.23.
//

import SwiftUI

struct PlayingQueueView: View {
#if !os(macOS)
    @Environment(\.editMode) private var editMode
#endif
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var VTM = VideoThumbnailsManager.main
    var body: some View {
        GeometryReader { geometry in
            Text("Next up")
                .font(.callout)
                .bold()
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical)
            let queueBinding: Binding<[YTAVPlayerItem]> = Binding(get: {
                return VideoPlayerModel.shared.player.items().compactMap({$0 as? YTAVPlayerItem}).filter({$0 != VideoPlayerModel.shared.currentItem})
            }, set: { newValue in
                VideoPlayerModel.shared.player.items().forEach {
                    if $0 != VideoPlayerModel.shared.currentItem {
                        VideoPlayerModel.shared.player.remove($0)
                    }
                }
                for item in newValue.reversed() {
                    VideoPlayerModel.shared.player.insert(item, after: VideoPlayerModel.shared.currentItem)
                }
            })
            List(queueBinding, id: \.self, editActions: [.move, .delete]) { $video in
                Button {
                    for item in VideoPlayerModel.shared.player.items().compactMap({$0 as? YTAVPlayerItem}) {
                        if item == video {
                            break
                        } else {
                            VideoPlayerModel.shared.player.remove(item)
                        }
                    }
                    VideoPlayerModel.shared.player.advanceToNextItem()
                } label: {
                    HStack {
                        Image(systemName: "line.3.horizontal")
                            .padding(.vertical)
                        VStack {
                            if let thumbnailData = VTM.images[video.videoId], let image = UIImage(data: thumbnailData){
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            } else {
                                CachedAsyncImage(url: video.video.thumbnails.first?.url, content: { content, _ in
                                    switch content {
                                    case .empty:
                                        Rectangle()
                                            .foregroundColor(colorScheme.backgroundColor)
                                    case .failure:
                                        Rectangle()
                                            .foregroundColor(colorScheme.backgroundColor)
                                    case .success(let image):
                                        image
                                            .resizable()
                                    @unknown default:
                                        Rectangle()
                                            .foregroundColor(colorScheme.backgroundColor)
                                    }
                                })
                            }
                        }
                        .frame(width: 70, height: 40)
                        VStack {
                            Text(video.videoTitle ?? "")
                                .font(.system(size: 15))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(video.channelName ?? "")
                                .font(.system(size: 13))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .listRowSeparator(.hidden)
                    .padding()
                    .contextMenu(menuItems: {
                        AddToQueueContextMenuButtonView(video: video.video, videoThumbnailData: VTM.images[video.videoId])
                    }, preview: {
                        VideoView(video: video.video, thumbnailData: VTM.images[video.videoId])
                    })
                }
                .buttonStyle(.plain)
            }
            .listStyle(.inset)
            .frame(width: geometry.size.width, height: geometry.size.height * 0.85)
        }
    }
}
