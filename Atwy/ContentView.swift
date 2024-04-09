//
//  ContentView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 19.11.22.
//

import SwiftUI
import CoreData
#if !os(macOS)
import MediaPlayer
#endif
import _AVKit_SwiftUI
import YouTubeKit

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var sheetAnimation
    @State private var errorText = ""
    @State private var showOverlay: Bool = true
    private var settingsSheetBinding = SheetsModel.shared.makeSheetBinding(.settings)
    private var watchVideoBinding = SheetsModel.shared.makeSheetBinding(.watchVideo)
    @ObservedObject private var MTVM = MainTabViewModel.shared
    @ObservedObject private var network = NetworkReachabilityModel.shared
    @ObservedObject private var APIM = APIKeyModel.shared
    @ObservedObject private var VPM = VideoPlayerModel.shared
    @ObservedObject private var IUTM = IsUserTypingModel.shared
    @ObservedObject private var DM = DownloadingsModel.shared
    @ObservedObject private var PM = PopupsModel.shared
    var body: some View {
        TabView(selection: $MTVM.currentTab) {
            TabBarElement(DestinationView: {
                if network.connected {
                    SearchView()
                } else {
                    NoConnectionView()
                }
            }, type: .search, name: "Home", image: "square.stack.fill")
                .environment(\.managedObjectContext, PersistenceModel.shared.context)
            TabBarElement(DestinationView: {FavoritesView()}, type: .favorites, name: "Favorites", image: "star.fill")
                .environment(\.managedObjectContext, PersistenceModel.shared.context)
            TabBarElement(DestinationView: {DownloadedVideosView()}, type: .downloads, name: "Downloads", image: "arrow.down.circle.fill")
                .environment(\.managedObjectContext, PersistenceModel.shared.context)
                .badge(DM.activeDownloadingsCount)
            TabBarElement(DestinationView: {
                if network.connected {
                    if !(APIM.userAccount?.isDisconnected ?? true) {
                        PersonnalAccountView()
                    } else if APIM.isFetchingAccountInfos {
                        LoadingView(customText: "account infos.")
                    } else {
                        NotConnectedToGoogleView()
                    }
                } else {
                    NoConnectionView()
                }
            }, type: .account, name: "Account", image: "person.circle")
        }
        .overlay(alignment: .bottom, content: {
            ZStack {
                let imageData = PM.shownPopup?.data as? Data
                switch PM.shownPopup?.type {
                case .addedToFavorites:
                    AddedFavoritesAlertView(imageData: imageData)
                case .addedToPlaylist:
                    AddedToPlaylistAlertView(imageData: imageData)
                case .cancelledDownload:
                    CancelledDownloadAlertView(imageData: imageData)
                case .deletedDownload:
                    DeletedDownloadAlertView(imageData: imageData)
                case .pausedDownload:
                    PausedDownloadAlertView(imageData: imageData)
                case .playLater:
                    PlayLaterAlertView(imageData: imageData)
                case .playNext:
                    PlayNextAlertView(imageData: imageData)
                case .resumedDownload:
                    ResumedDownloadAlertView(imageData: imageData)
                case .none:
                    Color.clear.frame(width: 0, height: 0)
                        .hidden()
                }
            }
            .padding(.bottom, 200)
        })
        .onAppear {
            #if !os(macOS)
            let appearance = UITabBarAppearance()
            appearance.backgroundEffect = UIBlurEffect(style: colorScheme.blurStyle)
            appearance.backgroundColor = UIColor(Color.black.opacity(0.0))

            // Use this appearance when scrolling behind the TabView:
            UITabBar.appearance().standardAppearance = appearance
            // Use this appearance when scrolled all the way up:
            UITabBar.appearance().scrollEdgeAppearance = appearance
            #endif
        }
        .safeAreaInset(edge: .bottom, content: {
            if !IUTM.userTyping && VPM.currentItem != nil {
                NowPlayingBarView(
                    sheetAnimation: sheetAnimation,
                    isSheetPresented: watchVideoBinding,
                    isSettingsSheetPresented: settingsSheetBinding.wrappedValue
                )
            }
        })
        .animation(.spring, value: !IUTM.userTyping && VPM.currentItem != nil)
    }
    
    @ViewBuilder
    private func TabBarElement<Destination>(@ViewBuilder DestinationView: () -> Destination, type: MainTabViewModel.Tab, name: String, image: String) -> some View where Destination: View {
        DestinationView()
            .tabItem {
                HStack {
                    ZStack {
                        Image(systemName: image)
                    }
                    Text(name)
                }
            }
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarBackground(.ultraThickMaterial, for: .tabBar)
            .tag(type)
    }
}

extension AVPlayer {
    var isPlaying: Bool {
        return rate != 0 && error == nil
    }
}

// KAVSOFT
extension View {
    var screenCornerRadius: CGFloat {
        let key = "_displayCornerRadius"
        if let screen = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.screen {
            if let cornerRadius = screen.value(forKey: key) as? CGFloat {
                return cornerRadius
            }
            return 0
        }
        return 0
    }
}
