//
//  VideoAppreciationView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 04.02.23.
//

import SwiftUI

struct VideoAppreciationView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingConfirmation: Bool = false
    @ObservedObject private var APIM = APIKeyModel.shared
    @ObservedObject private var NM = NetworkReachabilityModel.shared
    @ObservedObject private var VPM = VideoPlayerModel.shared
    var body: some View {
        if NM.connected, let likeStatus = VPM.moreVideoInfos?.authenticatedInfos?.likeStatus {
            VStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundStyle(.white)
                        .opacity(0.3)
                        .frame(height: 45)
                    HStack {
                        Spacer()
                        Text((likeStatus == .liked ? VPM.moreVideoInfos?.likesCount.likeButtonClickedNewValue : VPM.moreVideoInfos?.likesCount.defaultState) ?? "")
                            .foregroundStyle(.white)
                        Button {
                            if VPM.moreVideoInfos?.authenticatedInfos?.likeStatus == .liked {
                                DispatchQueue.main.async {
                                    VPM.isFetchingAppreciation = true
                                }
                                VPM.video?.removeLikeFromVideo(youtubeModel: YTM, result: { error in
                                    if let error = error {
                                        print("Error while removing like from video: \(error)")
                                    } else {
                                        DispatchQueue.main.async {
                                            VPM.moreVideoInfos?.authenticatedInfos?.likeStatus = .nothing
                                        }
                                    }
                                    DispatchQueue.main.async {
                                        VPM.isFetchingAppreciation = false
                                    }
                                })
                            } else if VPM.moreVideoInfos?.authenticatedInfos?.likeStatus == .nothing {
                                DispatchQueue.main.async {
                                    VPM.isFetchingAppreciation = true
                                }
                                VPM.video?.likeVideo(youtubeModel: YTM, result: { error in
                                    if let error = error {
                                        print("Error while liking video: \(error)")
                                    } else {
                                        DispatchQueue.main.async {
                                            VPM.moreVideoInfos?.authenticatedInfos?.likeStatus = .liked
                                        }
                                    }
                                    DispatchQueue.main.async {
                                        VPM.isFetchingAppreciation = false
                                    }
                                })
                            }
                        } label: {
                            Image(systemName: VPM.moreVideoInfos?.authenticatedInfos?.likeStatus == .liked ? "hand.thumbsup.fill" : "hand.thumbsup")
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
                                if VPM.moreVideoInfos?.authenticatedInfos?.likeStatus == .disliked {
                                    DispatchQueue.main.async {
                                        VPM.isFetchingAppreciation = true
                                    }
                                    VPM.video?.removeLikeFromVideo(youtubeModel: YTM, result: { error in
                                        if let error = error {
                                            print("Error while removing dislike from video: \(error)")
                                        } else {
                                            DispatchQueue.main.async {
                                                VPM.moreVideoInfos?.authenticatedInfos?.likeStatus = .nothing
                                            }
                                        }
                                        DispatchQueue.main.async {
                                            VPM.isFetchingAppreciation = false
                                        }
                                    })
                                } else if VPM.moreVideoInfos?.authenticatedInfos?.likeStatus == .nothing {
                                    DispatchQueue.main.async {
                                        VPM.isFetchingAppreciation = true
                                    }
                                    VPM.video?.likeVideo(youtubeModel: YTM, result: { error in
                                        if let error = error {
                                            print("Error while disliking video: \(error)")
                                        } else {
                                            DispatchQueue.main.async {
                                                VPM.moreVideoInfos?.authenticatedInfos?.likeStatus = .disliked
                                            }
                                        }
                                        DispatchQueue.main.async {
                                            VPM.isFetchingAppreciation = false
                                        }
                                    })
                                }
                            } label: {
                                Image(systemName: VPM.moreVideoInfos?.authenticatedInfos?.likeStatus == .disliked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
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
        }
    }
}
