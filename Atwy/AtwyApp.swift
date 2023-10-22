//
//  AtwyApp.swift
//  Atwy
//
//  Created by Antoine Bollengier on 19.11.22.
//

import SwiftUI
import YouTubeKit

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
    }
}
