//
//  AtwyApp.swift
//  Atwy
//
//  Created by Antoine Bollengier on 19.11.22.
//  Copyright © 2022-2025 Antoine Bollengier. All rights reserved.
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
                var newPath = NavigationPathModel.shared.getPathForTab(withType: self.currentTab)
                if !newPath.isEmpty { newPath.removeLast() }
                NavigationPathModel.shared.setPathForTab(withType: self.currentTab, path: newPath)
            }
        }
    }
    
    @Published var navigationPaths: [Tab: NavigationPath] = [
        .search: NavigationPath(),
        .account: NavigationPath(),
        .downloads: NavigationPath(),
        .favorites: NavigationPath()
    ]
    
    @Published var settingsSheetPath = NavigationPath()
    
    func getPathForTab(withType tabType: Tab) -> NavigationPath {
        if let path = self.navigationPaths[tabType] {
            return path
        } else {
            self.navigationPaths[tabType] = NavigationPath()
            return self.navigationPaths[tabType]!
        }
    }
    
    func appendToPath(_ element: any Hashable, toTab tabType: Tab) {
        DispatchQueue.main.async {
            if self.navigationPaths[tabType] == nil {
                self.navigationPaths[tabType] = NavigationPath()
                self.appendToPath(element, toTab: tabType)
            } else {
                self.navigationPaths[tabType]!.append(element)
            }
        }
    }
    
    func setPathForTab(withType tabType: Tab, path: NavigationPath) {
        DispatchQueue.main.async {
            self.navigationPaths[tabType] = path
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
    @UIApplicationDelegateAdaptor(ApplicationDelegate.self) var appDelegate
    
    @ObservedObject private var FMM = FileManagerModel.shared
    
    private var appWillTerminateObserver: NSObjectProtocol?
    
    init() {
        if #available(iOS 16.1, *) {
            // remove all the live activites in case the app crashes and the user relaunch it
            LiveActivitesManager.shared.removeAllActivities()
            
            // remove the live activites when the user terminate the app, does not take effect if the app crashed (TODO?)
            self.appWillTerminateObserver = NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: .main) { _ in
                LiveActivitesManager.shared.removeAllActivities()
            }
        }
        _ = PersistenceModel.shared // triggers the data fetching
        if YTM.logger == nil {
            YTM.logger = YouTubeModelLogger.shared
        }
        _ = APIKeyModel.shared
    }
    var body: some Scene {
        WindowGroup {
            /*
            NavigationStack(path: .constant(NavigationPath([RouteDestination.channelDetailsv2]))) {
                Color.clear
                    .routeContainer()
            }
             */
            
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
                            VideoPlayerModel.shared.loadVideo(video: YTVideo(videoId: sanitizedVideoId).withData())
                            SheetsModel.shared.showSheet(.watchVideo)
                        }
                    case "channel":
                        if let channelId = url.query?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
                           case .success(let sanitizedChannelId) = ParameterValidator.channelIdValidator.handler(channelId),
                           let sanitizedChannelId = sanitizedChannelId
                        {
                            //                                Atwy://watch?_u4GmLb_NCo
                            NavigationPathModel.shared.currentTab = .search // make sense to redirect the user to the search tab
                            NavigationPathModel.shared.appendToPath(RouteDestination.channelDetails(channel: YTLittleChannelInfos(channelId: sanitizedChannelId)), toTab: .search)
                        }
                    default:
                        break
                    }
                }
            })
            .persistentSystemOverlays(.hidden)
             
        }
    }
    
    private func handleSpotlightOpening(_ userActivity: NSUserActivity) {
        guard let itemAny = userActivity.userInfo?[CSSearchableItemActivityIdentifier], let itemPath =  itemAny as? String, let itemURL = URL(string: itemPath), let objectID = PersistenceModel.shared.controller.container.persistentStoreCoordinator.managedObjectID(forURIRepresentation: itemURL) else { return }
        
        let coreDataItem = PersistenceModel.shared.context.object(with: objectID)
        
        switch coreDataItem {
        case is DownloadedVideo:
            guard let video = coreDataItem as? DownloadedVideo else { break }
            loadVideoAndOpenSheet(video: video.toYTVideo().withData(.init(channelAvatarData: video.channel?.thumbnail, thumbnailData: video.thumbnail)))
        case is FavoriteVideo:
            guard let video = coreDataItem as? FavoriteVideo, NetworkReachabilityModel.shared.connected || (PersistenceModel.shared.getDownloadedVideo(videoId: video.videoId) != nil) else { break }
            loadVideoAndOpenSheet(video: video.toYTVideo().withData(.init(channelAvatarData: video.channel?.thumbnail, thumbnailData: video.thumbnailData)))
        case is DownloadedVideoChapter:
            guard let chapter = coreDataItem as? DownloadedVideoChapter, let video = chapter.video else { return }
            loadVideoAndOpenSheet(video: video.toYTVideo().withData(.init(channelAvatarData: video.channel?.thumbnail, thumbnailData: video.thumbnail)), seekTo: Double(chapter.startTimeSeconds))
        default:
            break
        }
        
        func loadVideoAndOpenSheet(video: YTVideoWithData, videoThumbnailData: Data? = nil, channelAvatarThumbnailData: Data? = nil, seekTo: Double? = nil) {
            if VideoPlayerModel.shared.currentItem?.videoId != video.video.videoId {
                VideoPlayerModel.shared.loadVideo(video: video, seekTo: seekTo)
            } else if let seekTo = seekTo, !VideoPlayerModel.shared.isLoadingVideo {
                VideoPlayerModel.shared.player.seek(to: CMTime(seconds: seekTo, preferredTimescale: 600))
            }
            SheetsModel.shared.showSheet(.watchVideo)
        }
    }
}
