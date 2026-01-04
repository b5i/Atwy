//
//  LocalCategoryView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 02.12.22.
//  Copyright © 2022-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//

import SwiftUI
import CoreData
import YouTubeKit
import OSLog

struct LocalCategoryView<LocalVideoType: LocalVideo>: View {
    let title: String
    var header: (() -> any View)? = nil
    @State private var search: String = ""
    @State private var width: CGFloat = .zero
    @ObservedObject private var VPM = VideoPlayerModel.shared
    @ObservedObject private var PSM = PreferencesStorageModel.shared
    
    private var currentSortDescriptor: NSSortDescriptor {            
        switch PSM[keyPath: LocalVideoType.sortSetting] {
        case .newest:
            return NSSortDescriptor(key: "timestamp", ascending: false)
        case .oldest:
            return NSSortDescriptor(key: "timestamp", ascending: true)
        case .title:
            return NSSortDescriptor(key: "title", ascending: true)
        case .channelName:
            return NSSortDescriptor(key: "channel.name", ascending: true)
        }
    }

    var body: some View {
        VStack {
            if let header {
                AnyView(header())
            }
            ScrollView {
                if width != 0 {
                    LocalCategoryListView<LocalVideoType>(
                        sortDescriptor: currentSortDescriptor,
                        search: search,
                        width: width
                    )
                } else {
                    Color.clear
                }
            }
        }
        .contentMargins(.bottom, length: VPM.currentItem != nil ? 50 : 0)
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { newValue in
            self.width = newValue.width
        }
        .routeContainer()
        #if os(macOS)
        .searchable(text: $search, placement: .toolbar)
        #else
        .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always))
        #endif
        .autocorrectionDisabled(true)
        .navigationTitle(title)
        .sortingModeSelectorButton(forPropertyPath:  LocalVideoType.sortSetting)
        .customNavigationTitleWithRightIcon {
            ShowSettingsButtonView()
        }
    }
}

struct LocalCategoryListView<LocalVideoType: LocalVideo>: View {
    @FetchRequest private var videos: FetchedResults<LocalVideoType>
    
    private let width: CGFloat
    @ObservedObject private var NM = NetworkReachabilityModel.shared
    @ObservedObject private var PSM = PreferencesStorageModel.shared
    
    init(sortDescriptor: NSSortDescriptor, search: String, width: CGFloat) {
        self.width = width
        
        let request = LocalVideoType.fetchRequest()
        
        request.sortDescriptors = [sortDescriptor]
        
        let searchWords = search
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: " ")
            .filter { !$0.isEmpty }
        
        if !searchWords.isEmpty {
            let wordPredicates = searchWords.map { word in
                // "title contains word OR channel.name contains word"
                // [cd] makes it Case Insensitive and Diacritic Insensitive (ignores accents)
                NSPredicate(format: "title CONTAINS[cd] %@ OR channel.name CONTAINS[cd] %@", word, word)
            }
            
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: wordPredicates)
        }
        
        request.fetchBatchSize = 30
        request.returnsObjectsAsFaults = true
        request.relationshipKeyPathsForPrefetching = ["channel"]
        
        _videos = FetchRequest(fetchRequest: request, animation: .default)
    }

    var body: some View {
        LazyVStack {
            let videoViewHeight = PSM.videoViewMode == .halfThumbnail ? 180 : width * 9/16 + 90
            
            ForEach(finalFilteredVideos) { video in
                let convertedResult = video.toYTVideo()
                
                VideoFromSearchView(videoWithData: convertedResult.withData(.init(channelAvatarData: video.channel?.thumbnail, thumbnailData: video.thumbnailData)))
                    .frame(width: width, height: videoViewHeight, alignment: .center)
                    .listRowSeparator(.hidden)
            }
            Color.clear.frame(height: 30)
        }
    }
    
    var finalFilteredVideos: [LocalVideoType] {
        if !NM.connected {
            return videos.filter {
                PersistenceModel.shared.isVideoDownloaded(videoId: $0.videoId) != nil
            }
        } else {
            return Array(videos)
        }
    }
}

