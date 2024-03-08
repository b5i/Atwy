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
    @ObservedObject private var DCMM = DownloadCoordinatorManagerModel.shared
    @ObservedObject private var APIM = APIKeyModel.shared
    @ObservedObject private var network = NetworkReachabilityModel.shared
    
    @State private var observer: (any NSObjectProtocol)? = nil
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
                NotificationCenter.default.post(name: .atwyDownloadingsChanged, object: nil)
                PopupsModel.shared.showPopup(.cancelledDownload)
            } label: {
                Text("Cancel all downloadings")
            }
            .buttonStyle(.bordered)
            List {
                let downloadersAndVideos: [(HLSDownloader, YTVideo)] =
                    DM.downloadings
                    .filter({$0.downloaderState == .downloading || $0.downloaderState == .waiting || $0.downloaderState == .paused})
                    .compactMap({ downloader in
                        if let video = downloader.video {
                            return (downloader, video)
                        }
                        return nil
                    })
                ForEach(downloadersAndVideos, id: \.0.self) { downloader, video in
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
                            DownloadButtonView(video: video)
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
            let selectedDownloader = DM.downloadings.filter({$0.downloaderState == .downloading || $0.downloaderState == .waiting || $0.downloaderState == .paused})[item]
            withAnimation {
                selectedDownloader.cancelDownload()
                downloads.removeAll(where: {$0.video?.videoId == selectedDownloader.video!.videoId})
                DownloadCoordinatorManagerModel.shared.launchDownloads()
            }
        }
    }
}
