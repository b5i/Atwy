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
    @ObservedObject private var PQM = PlayingQueueModel.shared
    @ObservedObject private var VTM = VideoThumbnailsManager.main
    var body: some View {
        Text("Next up")
        Divider()
        ScrollView {
#if os(macOS)
            List($PQM.queue, id: \.id) { $video in
                Button {
                    PQM.loadVideoWithID(video.id)
                    PQM.indexQueue()
                } label: {
                    HStack {
                        Image(systemName: "line.3.horizontal")
                            .padding(.vertical)
                        VStack {
                            if let thumbnailData = video.thumbnailData {
                                Image(nsImage: NSImage(data: thumbnailData)!)
                                    .resizable()
                            } else {
                                AsyncImage(url: URL(string: video.thumbnailFormats?.first ?? ""), content: { content in
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
                            Text(video.title ?? "")
                                .font(.system(size: 15))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(video.owner ?? "")
                                .font(.system(size: 13))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding()
                }
                .buttonStyle(.plain)
            }
            .frame(width: min(NSScreen.main?.frame.width ?? 800, NSScreen.main?.frame.height ?? 400), height: 200)
#else
            List($PQM.queue, id: \.id, editActions: [.move, .delete]) { $video in
                Button {
                    if let videoId = video.id {
                        PQM.loadVideoWithID(videoId)
                        PQM.indexQueue()
                    }
                } label: {
                    HStack {
                        Image(systemName: "line.3.horizontal")
                            .padding(.vertical)
                        VStack {
                            if let thumbnailData = VTM.images[video.videoId] {
                                Image(uiImage: UIImage(data: thumbnailData)!)
                                    .resizable()
                            } else {
                                CachedAsyncImage(url: video.thumbnails.first?.url, content: { content in
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
                            Text(video.title ?? "")
                                .font(.system(size: 15))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(video.channel?.name ?? "")
                                .font(.system(size: 13))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .listRowSeparator(.hidden)
                    .padding()
                    .contextMenu(menuItems: {
                        AddToQueueContextMenuButtonView(video: video, videoThumbnailData: VTM.images[video.videoId])
                    }, preview: {
                        VideoView(video: video, thumbnailData: VTM.images[video.videoId])
                    })
                }
                .buttonStyle(.plain)
            }
            .listStyle(.inset)
            .frame(width: min(UIScreen.main.bounds.width, UIScreen.main.bounds.height), height: 200)
#endif
        }
    }
}
