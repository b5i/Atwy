//
//  DownloadOptionsView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 23.04.23.
//

import SwiftUI
import YouTubeKit

struct DownloadOptionsView: View {
    let video: YTVideo
    let actionOnClick: ((any DownloadFormat)?) -> Void
    @State private var content: VideoInfosWithDownloadFormatsResponse?
    var body: some View {
        VStack {
            ScrollView {
                if let content = content {
                    ForEach(Array(content.downloadFormats.enumerated()), id: \.offset) { (_, format: any DownloadFormat) in
                        Button {
                            actionOnClick(format)
                        } label: {
                            formatButtonLabel(format: format)
                        }
                    }
                } else {
                    Text("Loading other options...")
                    ProgressView()
                }
            }
        }
        .onAppear {
            if content == nil {
                video.fetchStreamingInfosWithDownloadFormats(youtubeModel: YTM, infos: { result in
                    switch result {
                    case .success(let response):
                        DispatchQueue.main.async {
                            self.content = response
                        }
                    case .failure(let error):
                        print("Error while fetching download formats for video, error: \(error).")
                    }
                })
            }
        }
    }
    
    @ViewBuilder private func formatButtonLabel(format: any DownloadFormat) -> some View {
        VStack {
            if let contentLength = format.contentLength {
                let storageText: String = contentLength > 1_000_000_000 ? String(contentLength / 1_000_000_000) + "GB" : contentLength > 1_000_000 ? String(contentLength / 1_000_000) + "MB" : String(contentLength / 1_000) + "KB"
                if let videoFormat = format as? VideoInfosWithDownloadFormatsResponse.VideoDownloadFormat {
                    Text("\(videoFormat.quality ?? "") - \(storageText)")
                } else if let audioFormat = format as? VideoInfosWithDownloadFormatsResponse.AudioOnlyFormat {
                    Text("\((audioFormat.averageBitrate ?? 0) / 1_000)kbps - \(storageText)")
                }
            }
        }
    }
}
