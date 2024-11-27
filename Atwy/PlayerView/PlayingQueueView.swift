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
            var queueBinding: Binding<[YTAVPlayerItem]> = Binding(get: {
                return VideoPlayerModel.shared.player.items().compactMap { $0 as? YTAVPlayerItem }.filter { $0 != VideoPlayerModel.shared.currentItem }
            }, set: { newValue in
                VideoPlayerModel.shared.player.items().forEach {
                    if $0 != VideoPlayerModel.shared.currentItem {
                        VideoPlayerModel.shared.player.remove($0)
                    }
                }
                for item in newValue.reversed() {
                    VideoPlayerModel.shared.player.insert(item, after: VideoPlayerModel.shared.currentItem)
                }
                VideoPlayerModel.shared.player.updateEndAction()
            })
            List(queueBinding, id: \.self, editActions: [.move, .delete]) { $video in
                Button {
                    let items = VideoPlayerModel.shared.player.items().compactMap({ $0 as? YTAVPlayerItem })
                    let videoObject = video
                    var beforeItem: YTAVPlayerItem?
                    for item in items {
                        if item == videoObject {
                            break
                        } else {
                            beforeItem = item
                            if let beforeItem {
                                VideoPlayerModel.shared.player.remove(beforeItem)
                            }
                        }
                    }
                    VideoPlayerModel.shared.player.replaceCurrentItem(with: videoObject)
                    VideoPlayerModel.shared.player.updateEndAction()
                } label: {
                    HStack {
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
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(video.channelName ?? "")
                                .font(.system(size: 13))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(.white)
                            .padding(.vertical)
                    }
                    .listRowSeparator(.hidden)
                    .padding()
                    .contextMenu(menuItems: {
                        AddToQueueContextMenuButtonView(video: video.video, videoThumbnailData: VTM.images[video.videoId])
                    }, preview: {
                        VideoView(videoWithData: video.video.withData(.init(allowChannelLinking: false, thumbnailData: VTM.images[video.videoId])))
                    })
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .frame(width: geometry.size.width, height: geometry.size.height * 0.85)
            .padding(.vertical)
            .safeAreaInset(edge: .top, content: {
                ZStack {
                    VariableBlurView(orientation: .topToBottom)
                        .ignoresSafeArea()
                    Text("Next up")
                        .font(.callout)
                        .bold()
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                }
                .frame(height: 40)
            })
        }
    }
}
