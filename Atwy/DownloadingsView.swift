//
//  DownloadingsView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 27.12.22.
//

import SwiftUI
import YouTubeKit

struct DownloadingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var DM = DownloadersModel.shared
    @ObservedObject private var APIM = APIKeyModel.shared
    @ObservedObject private var network = NetworkReachabilityModel.shared
    @ObservedObject private var PM = PersistenceModel.shared
    
    @State private var observer: (any NSObjectProtocol)? = nil
    var body: some View {
        VStack {
            Button {
                for downloader in DM.downloaders.values {
                    DM.cancelDownloadFor(downloader: downloader)
                }
            } label: {
                Text("Cancel all downloadings")
            }
            .buttonStyle(.bordered)
            List {
                let downloaders: [HLSDownloader] = DM.activeDownloaders.sorted(by: {$0.downloadInfo.timestamp < $1.downloadInfo.timestamp})
                ForEach(downloaders, id: \.self) { (downloader: HLSDownloader) in
                    let video = downloader.downloadInfo.video
                        HStack {
                            VStack {
#if os(macOS)
                                if let image = NSImage(data: downloader.state.thumbnailData) {
                                    Image(nsImage: image)
                                        .resizable()
                                } else {
                                    Rectangle()
                                        .foregroundColor(.black)
                                }
#else
                                if let imageData = downloader.downloadInfo.thumbnailData, let image = UIImage(data: imageData) {
                                    Image(uiImage: image)
                                        .resizable()
                                } else {
                                    Rectangle()
                                        .foregroundColor(.black)
                                }
#endif
                            }
                            .frame(width: 55, height: 32)
                            VStack {
                                Text(video.title ?? "")
                                Text(video.channel?.name ?? "")
                                    .foregroundColor(.gray)
                                    .opacity(0.7)
                            }
                            .frame(width: 200, height: 50)
                            let downloadLocation: URL? = {
                                return PM.currentData.downloadedVideoIds.first(where: {$0.videoId == video.videoId})?.storageLocation
                            }()
                            DownloadButtonView(video: video, downloadURL: downloadLocation)
                        }
                        .contextMenu {
                            DownloadingItemsContextMenuView(downloader: downloader)
                        } preview: {
                            VideoView(videoWithData: video.withData(.init(allowChannelLinking: false)))
                        }
                        .swipeActions(allowsFullSwipe: false, content: {
                            DownloadSwipeActionsView(downloader: downloader)
                        })
                        .onTapGesture {
                            if VideoPlayerModel.shared.currentItem?.videoId != downloader.downloadInfo.video.videoId {
                                VideoPlayerModel.shared.loadVideo(video: downloader.downloadInfo.video)
                            }
                            SheetsModel.shared.showSheet(.watchVideo)
                        }
                    }
            }
        }
#if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .navigationTitle("Downloadings")
        .toolbar(content: {
            #if os(macOS)
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
            #else
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
            #endif
        })
        .navigationBarBackButtonHidden(true)
        .customNavigationTitleWithRightIcon {
            ShowSettingsButtonView()
        }
        .padding(.vertical)
        .onReceive(of: .atwyNoDownloadingsLeft, handler: { _ in
            dismiss()
        })
    }

    private func deleteItem(at offsets: IndexSet) {
        for item in offsets {
            let selectedDownloader = DM.activeDownloaders.sorted(by: {$0.downloadInfo.timestamp < $1.downloadInfo.timestamp})[item]
            DownloadersModel.shared.cancelDownloadFor(downloader: selectedDownloader)
        }
    }
}
