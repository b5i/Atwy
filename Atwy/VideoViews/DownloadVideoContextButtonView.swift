//
//  DownloadVideoContextButtonView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 23.04.23.
//  Copyright © 2023-2026 Antoine Bollengier. All rights reserved.
//

import SwiftUI
import YouTubeKit

struct DownloadVideoContextButtonView: View {
    @State private var downloadAction: ((any DownloadFormat)?) -> Void
    @State private var video: YTVideo
    var body: some View {
        Menu {
            Button {
                downloadAction(nil)
            } label: {
                Text("Default")
            }
            DownloadOptionsView(video: video, actionOnClick: { format in
                downloadAction(format)
            })
        } label: {
            HStack {
                Text("Download")
                Image(systemName: "arrow.down.circle")
                    .resizable()
                    .scaledToFit()
            }
        }
    }
}
