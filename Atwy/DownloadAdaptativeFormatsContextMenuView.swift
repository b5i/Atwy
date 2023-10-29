//
//  DownloadAdaptativeFormatsContextMenuView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 21.10.2023.
//

import Foundation
import SwiftUI
import YouTubeKit

struct DownloadAdaptativeFormatsContextMenuView: View {
    typealias VideoFormat = VideoInfosWithDownloadFormatsResponse.VideoDownloadFormat
    typealias AudioFormat = VideoInfosWithDownloadFormatsResponse.AudioOnlyFormat
    @State private var formats: VideoInfosWithDownloadFormatsResponse?
    @State var video: YTVideo
    @State var videoThumbnailData: Data?
    var body: some View {
        Menu(content: {
            if let formats = formats {
                Section("Video formats") {
                    ForEach(Array((formats.downloadFormats).enumerated()).filter({$0.element as? VideoFormat != nil}).filter({$0.element.mimeType == "video/mp4"}), id: \.offset) { _, format in
                        Button {
                            if let downloader = downloads.first(where: {$0.video?.videoId == video.videoId}) {
                                if downloader.downloaderState != .downloading && downloader.downloaderState != .success {
                                    downloader.downloadData = format

                                    DispatchQueue.main.async {
                                        downloader.video = video
                                        downloader.state.thumbnailData = videoThumbnailData
                                    }
                                    
                                    DownloadCoordinatorManagerModel.shared.appendDownloader(downloader: downloader)
                                }
                            } else {
                                let downloader = HLSDownloader()
                                downloader.downloadData = format

                                DispatchQueue.main.async {
                                    downloader.video = video
                                    downloader.state.thumbnailData = videoThumbnailData
                                }
                                
                                DownloadCoordinatorManagerModel.shared.appendDownloader(downloader: downloader)
                            }
                        } label: {
                            if let contentLength = format.contentLength {
                                let storageText: String = contentLength > 1_000_000_000 ? String(contentLength / 1_000_000_000) + "GB" : contentLength > 1_000_000 ? String(contentLength / 1_000_000) + "MB" : String(contentLength / 1_000) + "KB"
                                if let videoFormat = format as? VideoInfosWithDownloadFormatsResponse.VideoDownloadFormat {
                                    Text("\(videoFormat.quality ?? "") - \(storageText)")
                                }
                            }
                        }
                    }
                }
                Section("Audio formats") {
                    ForEach(Array((formats.downloadFormats).enumerated()).filter({$0.element as? AudioFormat != nil}).filter({$0.element.mimeType == "audio/mp4"}), id: \.offset) { _, format in
                        Button {
                            if let downloader = downloads.first(where: {$0.video?.videoId == video.videoId}) {
                                if downloader.downloaderState != .downloading && downloader.downloaderState != .success {
                                    downloader.downloadData = format

                                    DispatchQueue.main.async {
                                        downloader.video = video
                                        downloader.state.thumbnailData = videoThumbnailData
                                    }
                                    
                                    DownloadCoordinatorManagerModel.shared.appendDownloader(downloader: downloader)
                                }
                            } else {
                                let downloader = HLSDownloader()
                                downloader.downloadData = format
                                
                                DispatchQueue.main.async {
                                    downloader.video = video
                                    downloader.state.thumbnailData = videoThumbnailData
                                }
                                
                                DownloadCoordinatorManagerModel.shared.appendDownloader(downloader: downloader)
                            }
                        } label: {
                            if let contentLength = format.contentLength {
                                let storageText: String = contentLength > 1_000_000_000 ? String(contentLength / 1_000_000_000) + "GB" : contentLength > 1_000_000 ? String(contentLength / 1_000_000) + "MB" : String(contentLength / 1_000) + "KB"
                                if let audioFormat = format as? VideoInfosWithDownloadFormatsResponse.AudioOnlyFormat {
                                    Text("\((audioFormat.averageBitrate ?? 0) / 1_000)kbps - \(storageText)")
                                }
                            }
                        }
                    }
                }
            } else {
                Text("Loading formats...")
                    .task {
                        if self.formats == nil {
                            (self.formats, _) = await video.fetchStreamingInfosWithDownloadFormats(youtubeModel: YTM)
                        }
                    }
            }
        }, label: {
            Text("Downloads")
        })
    }
}
