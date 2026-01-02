//
//  DownloadStateView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 25.01.23.
//  Copyright © 2023-2026 Antoine Bollengier. All rights reserved.
//

import SwiftUI
import YouTubeKit

struct DownloadStateView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var downloader: HLSDownloader
    var body: some View {
        if downloader.percentComplete == 0.0 {
            ProgressView()
                .frame(width: 25, height: 25)
                .padding()
        } else {
            CircularProgressView(progress: downloader.percentComplete)
                .frame(width: 20, height: 20)
                .padding()
        }
    }
}

