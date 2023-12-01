//
//  AtwyApp.swift
//  Atwy
//
//  Created by Antoine Bollengier on 19.11.22.
//

import SwiftUI
import CoreSpotlight
import YouTubeKit
import AVFoundation

class NavigationPathModel: ObservableObject {
    @Published var path = NavigationPath()
}

let navigationPathModel = NavigationPathModel()

@main
struct AtwyApp: App {
    @State private var showChannelPopup: Bool = false
    @State private var currentChannel: String?
    @State private var isCleaningFiles: Bool = false
    @ObservedObject private var FMM = FileManagerModel.shared
    init() {
        Task {
            FileManagerModel.shared.fetchNewDownloadedVideosPaths()
        }
    }
    var body: some Scene {
        WindowGroup {
            Group {
                if !FMM.filesRemovedProgress {
                    VStack {
                        Text("Cleaning files...")
                            .font(.title2)
                            .bold()
                        Text("Do not close the app ")
                            .font(.caption)
                        ProgressView()
                            .padding(.top, 50)
                    }
                } else {
                    ContentView()
                        .environment(\.managedObjectContext, PersistenceModel.shared.context)
                        .onOpenURL(perform: { url in
                            print(url)
                            if url.scheme == "atwy" || url.scheme == "Atwy" {
                                switch url.host {
                                case "watch":
                                    if let videoId = url.query?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
                                        //                                Atwy://watch?_u4GmLb_NCo
                                        if videoId.count == 11 {
                                            print("received valid id")
                                            VideoPlayerModel.shared.loadVideo(video: YTVideo(videoId: videoId))
                                            SheetsModel.shared.showSheet(.watchVideo)
                                        }
                                    }
                                case "channel":
                                    if let channelID = url.query?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
                                        //                                Atwy://watch?_u4GmLb_NCo
                                        if channelID.count > 2 {
                                            print("received valid id")
                                            currentChannel = channelID
                                            showChannelPopup = true
                                        }
                                    }
                                default:
                                    break
                                }
                            }
                        })
                        .onAppear {
#if !os(macOS)
                            let appearance = UINavigationBarAppearance()
                            appearance.configureWithDefaultBackground()
                            UINavigationBar.appearance().scrollEdgeAppearance = appearance
#endif
                        }
                }
            }
            .onContinueUserActivity(CSSearchableItemActionType, perform: handleSpotlightOpening)
        }
    }
    
    private func handleSpotlightOpening(_ userActivity: NSUserActivity) {
        guard let itemAny = userActivity.userInfo?[CSSearchableItemActivityIdentifier], let itemPath =  itemAny as? String, let itemURL = URL(string: itemPath), let objectID = PersistenceModel.shared.controller.container.persistentStoreCoordinator.managedObjectID(forURIRepresentation: itemURL) else { return }
        
        let coreDataItem = PersistenceModel.shared.context.object(with: objectID)
        
        switch coreDataItem {
        case is DownloadedVideo:
            guard let video = coreDataItem as? DownloadedVideo else { break }
            loadVideoAndOpenSheet(video: video.toYTVideo(), videoThumbnailData: video.thumbnail, channelAvatarThumbnailData: video.channel?.thumbnail)
        case is FavoriteVideo:
            guard let video = coreDataItem as? FavoriteVideo else { break }
            loadVideoAndOpenSheet(video: video.toYTVideo(), videoThumbnailData: video.thumbnailData, channelAvatarThumbnailData: video.channel?.thumbnail)
        case is DownloadedVideoChapter:
            guard let chapter = coreDataItem as? DownloadedVideoChapter, let video = chapter.video else { return }
            loadVideoAndOpenSheet(video: video.toYTVideo(), videoThumbnailData: video.thumbnail, channelAvatarThumbnailData: video.channel?.thumbnail, seekTo: Double(chapter.startTimeSeconds))
        default:
            break
        }
        
        func loadVideoAndOpenSheet(video: YTVideo, videoThumbnailData: Data? = nil, channelAvatarThumbnailData: Data? = nil, seekTo: Double? = nil) {
            if VideoPlayerModel.shared.video?.videoId != video.videoId {
                VideoPlayerModel.shared.loadVideo(video: video, thumbnailData: videoThumbnailData, channelAvatarImageData: channelAvatarThumbnailData, seekTo: seekTo)
            } else if let seekTo = seekTo, !VideoPlayerModel.shared.isLoadingVideo {
                VideoPlayerModel.shared.player.seek(to: CMTime(seconds: seekTo, preferredTimescale: 600))
            }
            SheetsModel.shared.showSheet(.watchVideo)
        }
    }
}
