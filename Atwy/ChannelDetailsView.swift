//
//  ChannelDetailsView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 28.12.22.
//  Copyright © 2022-2025 Antoine Bollengier. All rights reserved.
//

import SwiftUI
import InfiniteScrollViews
import YouTubeKit
import OSLog

struct ChannelDetailsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    let channel: YTLittleChannelInfos
    @State private var navigationTitle: String = ""
    @StateObject private var model = Model()
    @State private var needToReload: Bool = true
    @State private var selectedMode: Int = 0
    @State private var selectedCategory: ChannelInfosResponse.RequestTypes? = .videos
    @State private var shouldReloadScrollView: Bool = false
    @State private var isChangingSubscriptionStatus: Bool = false
    
    @ObservedModel(VideoPlayerModel.shared, { model in
        return model.currentItem != nil
    }) private var hasVideoItem
    
    var body: some View {
        if model.isFetchingChannelInfos {
            HStack(alignment: .center) {
                Spacer()
                LoadingView()
                Spacer()
            }
        } else {
            VStack {
                if let channelInfos = model.channelInfos {
                    VStack {
                        VStack {
                            ChannelBannerRectangleView(channelBannerURL: channelInfos.bannerThumbnails.last?.url)
                                .overlay(alignment: .center) {
                                    let thumbnailsCount = channelInfos.avatarThumbnails.count
                                    if thumbnailsCount == 0 {
                                        UnknownAvatarView()
                                    } else if thumbnailsCount == 1 {
                                        ChannelAvatarCircleView(avatarURL: channelInfos.avatarThumbnails.first?.url)
                                    } else {
                                        ChannelAvatarCircleView(avatarURL: channelInfos.avatarThumbnails[thumbnailsCount - 2].url) // take the one before the last one
                                    }
                                }
                            Text(channelInfos.name ?? "")
                                .font(.title)
                                .bold()
                        }
                        /*
                         .onAppear {
                         navigationTitle = ""
                         }
                         .onDisappear {
                         navigationTitle = channelInfos.name ?? ""
                         }*/
                        HStack {
                            Text(channelInfos.handle ?? "")
                            if channelInfos.handle != nil, channelInfos.subscriberCount != nil {
                                Text(" • ")
                            }
                            Text(channelInfos.subscriberCount ?? "")
                            if channelInfos.subscriberCount != nil, channelInfos.videoCount != nil {
                                Text(" • ")
                            }
                            Text(channelInfos.videoCount ?? "")
                        }
                        .padding(.top)
                        .font(.system(size: 12))
                        .bold()
                        .opacity(0.5)
                        if channelInfos.isSubcribeButtonEnabled == true, let subscribeStatus = channelInfos.subscribeStatus {
                            Button {
                                Task {
                                    DispatchQueue.main.async {
                                        self.isChangingSubscriptionStatus = true
                                    }
                                    var actionError: (any Error)?
                                    do {
                                        if subscribeStatus {
                                            try await channel.unsubscribeThrowing(youtubeModel: YTM)
                                        } else {
                                            try await channel.subscribeThrowing(youtubeModel: YTM)
                                        }
                                    } catch {
                                        actionError = error
                                    }
                                    DispatchQueue.main.async {
                                        if actionError == nil {
                                            withAnimation {
                                                model.channelInfos?.subscribeStatus?.toggle()
                                            }
                                        }
                                        self.isChangingSubscriptionStatus = false
                                    }
                                }
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 5)
                                        .foregroundStyle(subscribeStatus ? colorScheme.textColor : .red)
                                    Text(subscribeStatus ? "Subscribed" : "Subscribe")
                                        .foregroundStyle(subscribeStatus ? colorScheme.backgroundColor == .white ? .white : .red : .white)
                                        .font(.callout)
                                }
                                .frame(width: 100, height: 35)
                            }
                            .disabled(isChangingSubscriptionStatus)
                        }
                        Divider()
                        Picker("", selection: $selectedMode, content: {
                            if model.channelInfos?.requestParams[.videos] != nil {
                                Text("Videos").tag(0)
                            }
                            if model.channelInfos?.requestParams[.shorts] != nil {
                                Text("Shorts").tag(1)
                            }
                            if model.channelInfos?.requestParams[.directs] != nil {
                                Text("Directs").tag(2)
                            }
                            if model.channelInfos?.requestParams[.playlists] != nil {
                                Text("Playlists").tag(3)
                            }
                        })
                        .pickerStyle(.segmented)
                        // only for iOS 17
                        //                        .onChange(of: selectedMode, initial: true, {
                        //                            selectedCategory = getCategoryForTabIndex(selectedMode)
                        //                            guard let newValueCategory = selectedCategory else { selectedMode = 0; selectedCategory = .videos ; return }
                        //                            if (model.channelInfos?.channelContentStore[newValueCategory] as? (any ListableChannelContent)) == nil {
                        //                                model.fetchCategoryContents(for: newValueCategory)
                        //                            }
                        //                        })
                        .onChange(of: selectedMode, perform: { _ in
                            selectedCategory = getCategoryForTabIndex(selectedMode)
                            guard let newValueCategory = selectedCategory else { selectedMode = 0; selectedCategory = .videos ; return }
                            if (model.channelInfos?.channelContentStore[newValueCategory] as? (any ListableChannelContent)) == nil {
                                model.fetchCategoryContents(for: newValueCategory)
                            }
                        })
                        if let selectedCategory = selectedCategory, model.fetchingStates[selectedCategory] == true {
                            Spacer()
                                .overlay(alignment: .center) {
                                    LoadingView()
                                }
                        }
                    }
                    if let selectedCategory = selectedCategory {
                        if model.fetchingStates[selectedCategory] != true {
                            if model.channelInfos?.channelContentStore[selectedCategory] as? (any ListableChannelContent) != nil {
                                let itemsBinding: Binding<[YTElementWithData]> = Binding(get: {
                                    return ((model.channelInfos?.channelContentStore[selectedCategory] as? (any ListableChannelContent))?.items ?? [])
                                        .map({ item in
                                            if var video = item as? YTVideo {
                                                video.channel?.thumbnails = self.channel.thumbnails
                                                
                                                let videoWithData = YTElementWithData(element: video, data: .init(allowChannelLinking: false))
                                                return videoWithData
                                            } else if var playlist = item as? YTPlaylist {
                                                playlist.channel?.thumbnails = self.channel.thumbnails
                                                
                                                let playlistWithData = YTElementWithData(element: playlist, data: .init(allowChannelLinking: false))
                                                return playlistWithData
                                            }
                                            return YTElementWithData(element: item, data: .init())
                                        })
                                }, set: { newValue in
                                    var itemsContents = model.channelInfos?.channelContentStore[selectedCategory] as? (any ListableChannelContent)
                                    itemsContents?.items = newValue.map(\.element)
                                    model.channelInfos?.channelContentStore[selectedCategory] = itemsContents
                                })
                                if itemsBinding.wrappedValue.isEmpty {
                                    VStack(alignment: .center) {
                                        Spacer()
                                        Text("No items in this category.")
                                        Spacer()
                                    }
                                } else {
                                    ElementsInfiniteScrollView(
                                        items: itemsBinding,
                                        shouldReloadScrollView: $shouldReloadScrollView,
                                        shouldAddBottomSpacing: hasVideoItem,
                                        fetchMoreResultsAction: {
                                            if !(model.fetchingStates[selectedCategory] ?? false) {
                                                model.fetchContentsContinuation(for: selectedCategory)
                                            }
                                        }
                                    )
                                    //.frame(width: mainGeometry.size.width, height: mainGeometry.size.height * 0.7 - 49 + (channelInfos.isSubcribeButtonEnabled == true && channelInfos.subscribeStatus != nil ? 35 : 70)) // 49 for the navigation bar and 35 for the subscribe button
                                    .id(selectedCategory)
                                }
                            } else {
                                VStack(alignment: .center) {
                                    Spacer()
                                    Text("No items in this category.")
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
            .onAppear {
                if needToReload {
                    model.fetchInfos(channel: channel, {
                        model.fetchCategoryContents(for: .videos)
                    })
                    needToReload = false
                }
            }
#if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .navigationTitle(navigationTitle)
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
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ShareButtonView(onTap: {
                        self.channel.showShareSheet()
                    })
                }
#endif
            })
            .navigationBarBackButtonHidden(true)
            //        .toolbar(content: {
            //            ShareChannelView(channelID: channelID)
            //        })
        }
    }
    
    private func getCategoryForTabIndex(_ tabIndex: Int) -> ChannelInfosResponse.RequestTypes? {
        switch tabIndex {
        case 0:
            return .videos
        case 1:
            return .shorts
        case 2:
            return .directs
        case 3:
            return .playlists
        default:
            return nil
        }
    }
    
    class Model: ObservableObject {
        @Published var channelInfos: ChannelInfosResponse?
        
        @Published var isFetchingChannelInfos: Bool = false
        
        @Published var fetchingStates: [ChannelInfosResponse.RequestTypes : Bool] = [:]
        
        @Published var continuationsFetchingStates: [ChannelInfosResponse.RequestTypes : Bool] = [:]
        
        private var channel: YTLittleChannelInfos?
            
        public func fetchInfos(channel: YTLittleChannelInfos, _ end: (() -> Void)? = nil) {
            self.channel = channel
            DispatchQueue.main.async {
                self.isFetchingChannelInfos = true
                self.channelInfos = nil
            }
            ChannelInfosResponse.sendNonThrowingRequest(youtubeModel: YTM, data: [.browseId: channel.channelId], result: { result in
                switch result {
                case .success(let response):
                    DispatchQueue.main.async {
                        self.channelInfos = response
                        self.isFetchingChannelInfos = false
                        end?()
                    }
                case .failure(let error):
                    Logger.atwyLogs.simpleLog("Couldn't fetch channel infos: \(error)")
                }
            })
        }
        
        public func fetchCategoryContents(for category: ChannelInfosResponse.RequestTypes) {
            if let channelId = self.channel?.channelId, let requestParams = self.channelInfos?.requestParams[category] {
                DispatchQueue.main.async {
                    self.channelInfos?.channelContentStore.removeValue(forKey: category)
                    self.fetchingStates[category] = true
                }
                ChannelInfosResponse.sendNonThrowingRequest(youtubeModel: YTM, data: [.browseId: channelId, .params: requestParams], result: { result in
                    switch result {
                    case .success(let response):
                        DispatchQueue.main.async {
                            self.channelInfos?.channelContentStore[category] = response.currentContent
                            self.channelInfos?.channelContentContinuationStore[category] = response.channelContentContinuationStore[category]
                        }
                    case .failure(let error):
                        Logger.atwyLogs.simpleLog("Error while fetching \(String(describing: category)): \(error.localizedDescription)")
                    }
                    DispatchQueue.main.async {
                        self.fetchingStates[category] = false
                    }
                })
            }
        }
        
        public func fetchContentsContinuation(for category: ChannelInfosResponse.RequestTypes) {
            guard self.continuationsFetchingStates[category] != true else { return }
                        
            func fetchContentsContinuationRequest<Category>(category: Category.Type) where Category: ListableChannelContent {
                DispatchQueue.main.async {
                    self.continuationsFetchingStates[category.type] = true
                }
                channelInfos?.getChannelContentContinuation(Category.self, youtubeModel: YTM, result: { (result: Result<ChannelInfosResponse.ContentContinuation<Category>, Error>) in
                    switch result {
                    case .success(let response):
                        DispatchQueue.main.async {
                            self.channelInfos?.mergeListableChannelContentContinuation(response)
                        }
                    case .failure(let error):
                        Logger.atwyLogs.simpleLog("Error while fetching \(String(describing: category)): \(error.localizedDescription)")
                        break;
                    }
                    DispatchQueue.main.async {
                        self.continuationsFetchingStates[category.type] = false
                    }
                })
            }
            
            if let channelInfos = self.channelInfos, (channelInfos.channelContentContinuationStore[category] ?? nil) != nil {
                guard let categoryCastedType: any ListableChannelContent.Type = getChannelContinuationContentTypeFor(category: category) else { return }
                
                fetchContentsContinuationRequest(category: categoryCastedType)
            }
            
            func getChannelContinuationContentTypeFor(category: ChannelInfosResponse.RequestTypes) -> (any ListableChannelContent.Type)? {
                switch category {
                case .directs:
                    return ChannelInfosResponse.Directs.self
                case .playlists:
                    return ChannelInfosResponse.Playlists.self
                case .shorts:
                    return ChannelInfosResponse.Shorts.self
                case .videos:
                    return ChannelInfosResponse.Videos.self
                default:
                    return nil
                }
            }
        }
    }
}
