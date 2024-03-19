//
//  SubscribeButtonView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 19.02.23.
//

import SwiftUI

struct SubscribeButtonView: View {
    @State private var isFetching: Bool = false
    @ObservedObject private var APIM = APIKeyModel.shared
    @ObservedObject private var VPM = VideoPlayerModel.shared
    var body: some View {
        HStack {
            if let moreVideoInfos = VPM.currentItem?.moreVideoInfos {
                CachedAsyncImage(url: moreVideoInfos.channel?.thumbnails.first?.url, content: { image, _ in
                    switch image {
                    case .success(let imageCustom):
                        imageCustom
                            .resizable()
                            .clipShape(Circle())
                            .frame(width: 30, height: 30)
                    default:
                        Color.clear.frame(width: 0, height: 0)
                    }
                })
                Text(moreVideoInfos.channel?.name ?? "")
                if APIM.userAccount != nil && APIM.googleCookies != "" {
                    if isFetching {
                        ProgressView()
                            .padding(.horizontal)
                    } else {
                        if let authenticatedInfos  = moreVideoInfos.authenticatedInfos, let channel = moreVideoInfos.channel {
                            if authenticatedInfos.subscriptionStatus ?? false {
                                Button {
                                    DispatchQueue.main.async {
                                        self.isFetching = true
                                    }
                                    channel.unsubscribe(youtubeModel: YTM, result: { error in
                                        if let error = error {
                                            print("Error while unsubscribing to channel: \(error)")
                                        }
                                        DispatchQueue.main.async {
                                            self.isFetching = false
                                        }
                                    })
                                } label: {
                                    Text("Unsubsribe")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.white)
                            } else {
                                Button {
                                    DispatchQueue.main.async {
                                        self.isFetching = true
                                    }
                                    channel.subscribe(youtubeModel: YTM, result: { error in
                                        if let error = error {
                                            print("Error while subscribing to channel: \(error)")
                                        }
                                        DispatchQueue.main.async {
                                            self.isFetching = false
                                        }
                                    })
                                } label: {
                                    Text("Subscribe")
                                        .foregroundColor(.white)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.red)
                            }
                        }
                    }
                }
            }
        }
    }
}
