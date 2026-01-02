//
//  VideoAppreciationView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 04.02.23.
//  Copyright © 2023-2026 Antoine Bollengier. All rights reserved.
//

import SwiftUI
import OSLog
import YouTubeKit

struct VideoAppreciationView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingConfirmation: Bool = false
    @ObservedProperty(APIKeyModel.shared, \.userAccount, \.$userAccount) private var userAccount
    private var hasAccount: Bool { userAccount != nil }
    
    @ObservedObject private var NM = NetworkReachabilityModel.shared
    
    @MutableObservedProperty(VideoPlayerModel.shared, \.isFetchingAppreciation, \.$isFetchingAppreciation) private var isFetchingAppreciation
    @ObservedProperty<YTAVPlayerItem, MoreVideoInfosResponse?> private var moreVideoInfos: MoreVideoInfosResponse?
    let currentItem: YTAVPlayerItem
    
    init(currentItem: YTAVPlayerItem) {
        self.currentItem = currentItem
        self._moreVideoInfos = ObservedProperty(currentItem, \.moreVideoInfos, \.$moreVideoInfos)
    }
    
    var body: some View {
        let shouldShowWidget = NM.connected && (moreVideoInfos?.likesCount.defaultState ?? "") != ""
        PlayerQuickActionView {
            HStack {
                let likeStatus = moreVideoInfos?.authenticatedInfos?.likeStatus
                Text((likeStatus == .liked ? moreVideoInfos?.likesCount.clickedState : moreVideoInfos?.likesCount.defaultState) ?? "")
                    .foregroundStyle(.white)
                    .fixedSize()
                Button {
                    guard let likeStatus = likeStatus else { return }
                    DispatchQueue.main.async {
                        isFetchingAppreciation = true
                    }
                    switch likeStatus {
                    case .liked:
                        currentItem.video.removeLikeFromVideo(youtubeModel: YTM, result: { error in
                            if let error = error {
                                Logger.atwyLogs.simpleLog("Error while removing like from video: \(error)")
                            } else {
                                currentItem.setNewLikeStatus(.nothing)
                            }
                            DispatchQueue.main.async {
                                isFetchingAppreciation = false
                            }
                        })
                    case .disliked, .nothing:
                        currentItem.video.likeVideo(youtubeModel: YTM, result: { error in
                            if let error = error {
                                Logger.atwyLogs.simpleLog("Error while liking video: \(error)")
                            } else {
                                currentItem.setNewLikeStatus(.liked)
                            }
                            DispatchQueue.main.async {
                                isFetchingAppreciation = false
                            }
                        })
                    }
                } label: {
                    Image(systemName: likeStatus == .liked ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .foregroundStyle(.white)
                }
                .frame(width: 40, height: 40)
                .buttonStyle(.borderless)
                .hapticFeedbackOnTap(style: isFetchingAppreciation || hasAccount ? nil : .soft)
                .disabled(isFetchingAppreciation || !hasAccount)
                .padding(.vertical)
                .foregroundColor(.white)
                if hasAccount {
                    Divider()
                        .overlay(.white)
                        .padding(.vertical)
                        .frame(height: 45)
                    Button {
                        guard let likeStatus = likeStatus else { return }
                        DispatchQueue.main.async {
                            isFetchingAppreciation = true
                        }
                        switch likeStatus {
                        case .disliked:
                            currentItem.video.removeLikeFromVideo(youtubeModel: YTM, result: { error in
                                if let error = error {
                                    Logger.atwyLogs.simpleLog("Error while removing dislike from video: \(error)")
                                } else {
                                    currentItem.setNewLikeStatus(.nothing)
                                }
                                DispatchQueue.main.async {
                                    isFetchingAppreciation = false
                                }
                            })
                        case .nothing, .liked:
                            currentItem.video.dislikeVideo(youtubeModel: YTM, result: { error in
                                if let error = error {
                                    Logger.atwyLogs.simpleLog("Error while disliking video: \(error)")
                                } else {
                                    currentItem.setNewLikeStatus(.disliked)
                                }
                                DispatchQueue.main.async {
                                    isFetchingAppreciation = false
                                }
                            })
                        }
                    } label: {
                        Image(systemName: likeStatus == .disliked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                            .foregroundStyle(.white)
                    }
                    .frame(width: 40, height: 40)
                    .buttonStyle(.borderless)
                    .hapticFeedbackOnTap(style: isFetchingAppreciation ? nil : .soft)
                    .disabled(isFetchingAppreciation)
                    .padding(.vertical)
                    .foregroundColor(colorScheme.textColor)
                }
            }
        } action: {}
        .frame(width: shouldShowWidget ? (hasAccount /* the user can't like the video so we only show the likes count */ ? 180 : 110) : 0)
        .opacity(shouldShowWidget ? 1 : 0)
        .padding(.horizontal, shouldShowWidget ? 5 : 0)
    }
}
