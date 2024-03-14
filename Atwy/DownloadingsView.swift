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
    @ObservedObject private var DM = DownloadingsModel.shared
    @ObservedObject private var APIM = APIKeyModel.shared
    @ObservedObject private var network = NetworkReachabilityModel.shared
    @ObservedObject private var PM = PersistenceModel.shared
    
    @State private var observer: (any NSObjectProtocol)? = nil
    var body: some View {
        VStack {
            Button {
                for downloader in DM.downloadings.values {
                    downloader.cancelDownload()
                }
            } label: {
                Text("Cancel all downloadings")
            }
            .buttonStyle(.bordered)
            List {
                ForEach(DM.activeDownloadings.sorted(by: {$0.creationDate < $1.creationDate})) { downloader in
                    let video = downloader.video
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
                                if let imageData = downloader.state.thumbnailData, let image = UIImage(data: imageData) {
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
                            VideoView(video: video)
                        }
                        .swipeActions(allowsFullSwipe: false, content: {
                            DownloadSwipeActionsView(downloader: downloader)
                        })
                        .onTapGesture {
                            if VideoPlayerModel.shared.video?.videoId != downloader.video.videoId {
                                VideoPlayerModel.shared.loadVideo(video: downloader.video)
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
        .onAppear {
            self.observer = NotificationCenter.default.addObserver(forName: .atwyNoDownloadingsLeft, object: nil, queue: nil, using: { _ in
                dismiss()
            })
        }
        .onDisappear {
            if let observer = self.observer {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }

    private func deleteItem(at offsets: IndexSet) {
        for item in offsets {
            let selectedDownloader = DM.activeDownloadings.sorted(by: {$0.creationDate < $1.creationDate})[item]
            DownloadingsModel.shared.cancelDownloadFor(downloader: selectedDownloader)
        }
    }
}
