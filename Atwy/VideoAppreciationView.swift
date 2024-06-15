//
//  VideoAppreciationView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 04.02.23.
//

import SwiftUI
import OSLog

struct VideoAppreciationView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingConfirmation: Bool = false
    @ObservedObject private var APIM = APIKeyModel.shared
    @ObservedObject private var NM = NetworkReachabilityModel.shared
    @ObservedObject private var VPM = VideoPlayerModel.shared
    
    @ObservedObject var currentItem: YTAVPlayerItem
    var body: some View {
        let shouldShowWidget = NM.connected && (currentItem.moreVideoInfos?.likesCount.defaultState ?? "") != ""
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .foregroundStyle(.white)
                    .opacity(0.3)
                    .frame(height: 45)
                HStack {
                    let likeStatus = currentItem.moreVideoInfos?.authenticatedInfos?.likeStatus
                    Spacer()
                    Text((likeStatus == .liked ? currentItem.moreVideoInfos?.likesCount.clickedState : currentItem.moreVideoInfos?.likesCount.defaultState) ?? "")
                        .foregroundStyle(.white)
                    Button {
                        guard let likeStatus = likeStatus else { return }
                        DispatchQueue.main.async {
                            VPM.isFetchingAppreciation = true
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
                                    VPM.isFetchingAppreciation = false
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
                                    VPM.isFetchingAppreciation = false
                                }
                            })
                        }
                    } label: {
                        Image(systemName: likeStatus == .liked ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .foregroundStyle(.white)
                    }
                    .frame(width: 40, height: 40)
                    .buttonStyle(.borderless)
                    .hapticFeedbackOnTap(style: VPM.isFetchingAppreciation || (APIM.userAccount != nil) ? nil : .soft)
                    .disabled(VPM.isFetchingAppreciation || APIM.userAccount == nil)
                    .padding(.vertical)
                    .foregroundColor(.white)
                    if APIM.userAccount != nil {
                        Divider()
                            .overlay(.white)
                            .padding(.vertical)
                            .frame(height: 45)
                        Button {
                            guard let likeStatus = likeStatus else { return }
                            DispatchQueue.main.async {
                                VPM.isFetchingAppreciation = true
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
                                        VPM.isFetchingAppreciation = false
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
                                        VPM.isFetchingAppreciation = false
                                    }
                                })
                            }
                        } label: {
                            Image(systemName: likeStatus == .disliked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                                .foregroundStyle(.white)
                        }
                        .frame(width: 40, height: 40)
                        .buttonStyle(.borderless)
                        .hapticFeedbackOnTap(style: VPM.isFetchingAppreciation ? nil : .soft)
                        .disabled(VPM.isFetchingAppreciation)
                        .padding(.vertical)
                        .foregroundColor(colorScheme.textColor)
                    }
                    Spacer()
                }
            }
        }
        .frame(width: shouldShowWidget ? (APIM.userAccount != nil /* the user can't like the video so we only show the likes count */ ? 180 : 110) : 0)
        .opacity(shouldShowWidget ? 1 : 0)
    }
}
