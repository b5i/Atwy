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
import BackgroundTasks
import ActivityKit

class NavigationPathModel: ObservableObject {
    static let shared = NavigationPathModel()
    
    @Published var currentTab: Tab = .search {
        didSet {
            if self.currentTab == oldValue {
                var newPath = NavigationPathModel.shared.getPathForTab(self.currentTab)
                if !newPath.isEmpty { newPath.removeLast() }
                NavigationPathModel.shared.setPathForTab(self.currentTab, path: newPath)
            }
        }
    }
    
    @Published var searchTabPath = NavigationPath()
    @Published var favoritesTabPath = NavigationPath()
    @Published var downloadsTabPath = NavigationPath()
    @Published var connectedAccountTabPath = NavigationPath()
    
    @Published var settingsSheetPath = NavigationPath()
    
    func getPathForTab(_ tabType: Tab) -> NavigationPath {
        switch tabType {
        case .search:
            return self.searchTabPath
        case .favorites:
            return self.favoritesTabPath
        case .downloads:
            return self.downloadsTabPath
        case .account:
            return self.connectedAccountTabPath
        }
    }
    
    func setPathForTab(_ tabType: Tab, path: NavigationPath) {
        DispatchQueue.main.async {
            switch tabType {
            case .search:
                self.searchTabPath = path
            case .favorites:
                self.favoritesTabPath = path
            case .downloads:
                self.downloadsTabPath = path
            case .account:
                self.connectedAccountTabPath = path
            }
        }
    }
    
    enum Tab: CaseIterable {
        case search
        case favorites
        case downloads
        case account
    }
}

@main
struct AtwyApp: App {
    @State private var isCleaningFiles: Bool = false
    @ObservedObject private var FMM = FileManagerModel.shared
    @ObservedObject private var PSM = PreferencesStorageModel.shared
    
    private var appWillTerminateObserver: NSObjectProtocol
    
    init() {
        if #available(iOS 16.1, *) {
            DownloadingsProgressActivity.registerTask()
        }
        Task {
            FileManagerModel.shared.updateNewDownloadPathsAndCleanUpFiles()
        }
        if YTM.logger == nil {
            YTM.logger = YouTubeModelLogger.shared
        }
        // remove all the live activites in case the app crashes and the user relaunch it
        LiveActivitesManager.shared.removeAllActivities()
        
        // remove the live activites when the user terminate the app, does not take effect if the app crashed (TODO?)
        self.appWillTerminateObserver = NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: .main) { _ in
            LiveActivitesManager.shared.removeAllActivities()
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
                        .onAppear {
#if !os(macOS)
                            let appearance = UINavigationBarAppearance()
                            appearance.configureWithDefaultBackground()
                            UINavigationBar.appearance().scrollEdgeAppearance = appearance
#endif
                        }
                        .id(PSM.propetriesState[.customSearchBarEnabled] as? Bool != false)
                }
            }
            .onContinueUserActivity(CSSearchableItemActionType, perform: handleSpotlightOpening)
            .onOpenURL(perform: { url in
                if url.scheme == "atwy" || url.scheme == "Atwy" {
                    switch url.host {
                    case "watch":
                        if let videoId = url.query?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
                           case .success(let sanitizedVideoId) = ParameterValidator.videoIdValidator.handler(videoId),
                           let sanitizedVideoId = sanitizedVideoId
                        {
                            //                                Atwy://watch?_u4GmLb_NCo
                            VideoPlayerModel.shared.loadVideo(video: YTVideo(videoId: sanitizedVideoId))
                            SheetsModel.shared.showSheet(.watchVideo)
                        }
                    case "channel":
                        if let channelId = url.query?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
                           case .success(let sanitizedChannelId) = ParameterValidator.channelIdValidator.handler(channelId),
                           let sanitizedChannelId = sanitizedChannelId
                        {
                            //                                Atwy://watch?_u4GmLb_NCo
                            NavigationPathModel.shared.currentTab = .search // make sense to redirect the user to the search tab
                            NavigationPathModel.shared.searchTabPath.append(RouteDestination.channelDetails(channel: YTLittleChannelInfos(channelId: sanitizedChannelId)))
                        }
                    default:
                        break
                    }
                }
            })
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
            guard let video = coreDataItem as? FavoriteVideo, NetworkReachabilityModel.shared.connected || (PersistenceModel.shared.getDownloadedVideo(videoId: video.videoId) != nil) else { break }
            loadVideoAndOpenSheet(video: video.toYTVideo(), videoThumbnailData: video.thumbnailData, channelAvatarThumbnailData: video.channel?.thumbnail)
        case is DownloadedVideoChapter:
            guard let chapter = coreDataItem as? DownloadedVideoChapter, let video = chapter.video else { return }
            loadVideoAndOpenSheet(video: video.toYTVideo(), videoThumbnailData: video.thumbnail, channelAvatarThumbnailData: video.channel?.thumbnail, seekTo: Double(chapter.startTimeSeconds))
        default:
            break
        }
        
        func loadVideoAndOpenSheet(video: YTVideo, videoThumbnailData: Data? = nil, channelAvatarThumbnailData: Data? = nil, seekTo: Double? = nil) {
            if VideoPlayerModel.shared.currentItem?.videoId != video.videoId {
                VideoPlayerModel.shared.loadVideo(video: video, thumbnailData: videoThumbnailData, channelAvatarImageData: channelAvatarThumbnailData, seekTo: seekTo)
            } else if let seekTo = seekTo, !VideoPlayerModel.shared.isLoadingVideo {
                VideoPlayerModel.shared.player.seek(to: CMTime(seconds: seekTo, preferredTimescale: 600))
            }
            SheetsModel.shared.showSheet(.watchVideo)
        }
    }
}
