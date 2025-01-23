//
//  DownloadAdaptativeFormatsContextMenuView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 21.10.2023.
//

import Foundation
import SwiftUI
import YouTubeKit
import OSLog

struct DownloadAdaptativeFormatsContextMenuView: View {
    typealias VideoFormat = VideoInfosWithDownloadFormatsResponse.VideoDownloadFormat
    typealias AudioFormat = VideoInfosWithDownloadFormatsResponse.AudioOnlyFormat
    @State private var formats: VideoInfosResponse?
    let video: YTVideo
    let videoThumbnailData: Data?
    
    @ObservedObject private var DM = DownloadersModel.shared
    var body: some View {
        Menu(content: {
            if let formats = formats {
                Section("Video formats") {
                    ForEach(Array((formats.downloadFormats).enumerated()).filter({$0.element as? VideoFormat != nil}).filter({$0.element.mimeType == "video/mp4"}), id: \.offset) { _, format in
                        Button {
                            if let downloader = DM.downloaders[video.videoId] {
                                if downloader.downloaderState != .downloading && downloader.downloaderState != .success && downloader.downloaderState != .waiting && downloader.downloaderState != .paused {
                                    downloader.downloadData = format

                                    downloader.downloadInfo.thumbnailData = videoThumbnailData
                                    downloader.downloaderState = .waiting
                                    DM.launchDownloaders()
                                }
                            } else {
                                let downloader = HLSDownloader(video: self.video)
                                downloader.downloadData = format

                                downloader.downloadInfo.thumbnailData = videoThumbnailData
                                DM.addDownloader(downloader)
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
                            if let downloader = DM.downloaders[video.videoId] {
                                if downloader.downloaderState != .downloading && downloader.downloaderState != .success && downloader.downloaderState != .waiting && downloader.downloaderState != .paused {
                                    downloader.downloadData = format

                                    downloader.downloadInfo.thumbnailData = videoThumbnailData
                                    downloader.downloaderState = .waiting
                                    
                                    DM.launchDownloaders()
                                    
                                }
                            } else {
                                let downloader = HLSDownloader(video: self.video)
                                downloader.downloadData = format
                                
                                downloader.downloadInfo.thumbnailData = videoThumbnailData
                                
                                DM.addDownloader(downloader)
                            }
                        } label: {
                            if let contentLength = format.contentLength {
                                let storageText: String = contentLength > 1_000_000_000 ? String(contentLength / 1_000_000_000) + "GB" : contentLength > 1_000_000 ? String(contentLength / 1_000_000) + "MB" : String(contentLength / 1_000) + "KB"
                                if let audioFormat = format as? VideoInfosWithDownloadFormatsResponse.AudioOnlyFormat {
                                    Text("\(audioFormat.formatLocaleInfos?.displayName ?? "") - \((audioFormat.averageBitrate ?? 0) / 1_000)kbps - \(storageText)")
                                }
                            }
                        }
                    }
                }
            } else {
                Text("Loading formats...")
                    .task {
                        if self.formats == nil {
                            // get the visitorData if it isn't already set
                            if YTM.visitorData.isEmpty {
                                if let visitorData = try? await SearchResponse.sendThrowingRequest(youtubeModel: YTM, data: [.query: "homefwhfjoifj"]).visitorData {
                                    YTM.visitorData = visitorData
                                } else {
                                    Logger.atwyLogs.simpleLog("Couldn't get visitorData, request may fail.")
                                }
                            }
                            self.formats = try? await video.fetchStreamingInfosThrowing(youtubeModel: YTM)
                        }
                    }
            }
        }, label: {
            Text("Downloads")
        })
    }
}
