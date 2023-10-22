//
//  DownloadingsView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 27.12.22.
//

import SwiftUI

struct DownloadingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var DM = DownloadingsModel.shared
    @ObservedObject private var DCMM = DownloadCoordinatorManagerModel.shared
    @ObservedObject private var APIM = APIKeyModel.shared
    @ObservedObject private var network = NetworkReachabilityModel.shared
    var body: some View {
        VStack {
            Button {
                for downloader in DCMM.downloadings {
                    downloader.cancelDownload()
                }
                for downloader in DCMM.waitingDownloadings {
                    downloader.cancelDownload()
                }
                for downloader in DCMM.pausedDownloadings {
                    downloader.cancelDownload()
                }
                downloads = []
                NotificationCenter.default.post(name: Notification.Name("DownloadingChanged"), object: nil)
                PopupsModel.shared.showPopup(.cancelledDownload)
            } label: {
                Text("Cancel all downloadings")
            }
            .buttonStyle(.bordered)
            List {
                ForEach(DM.downloadings.filter({$0.downloaderState == .downloading || $0.downloaderState == .waiting || $0.downloaderState == .paused}), id: \.self) { downloader in
                    if let video = downloader.video {
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
                            DownloadStateView(displayRemainingTime: true, downloaded: false, video: video, isShort: downloader.isShort, downloader: downloader)
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
                            let video = downloader.video!
                            if VideoPlayerModel.shared.video?.videoId != video.videoId {
                                VideoPlayerModel.shared.loadVideo(video: video)
                            }
                            SheetsModel.shared.showSheet(.watchVideo)
                        }
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
            ShowSettingsButton()
        })
        .navigationBarBackButtonHidden(true)
        .padding(.vertical)
        .onAppear {
            NotificationCenter.default.addObserver(forName: Notification.Name("NoDownloadingsLeft"), object: nil, queue: nil, using: { _ in
                dismiss()
            })
        }
    }

    private func deleteItem(at offsets: IndexSet) {
        for item in offsets {
            let selectedDownloader = DM.downloadings.filter({$0.downloaderState == .downloading || $0.downloaderState == .waiting || $0.downloaderState == .paused})[item]
            withAnimation {
                selectedDownloader.cancelDownload()
                downloads.removeAll(where: {$0.video?.videoId == selectedDownloader.video!.videoId})
                DownloadCoordinatorManagerModel.shared.launchDownloads()
            }
        }
    }
}
