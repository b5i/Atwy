//
//  VideoInScrollView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 08.07.2024.
//  Copyright © 2024-2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI

struct VideoInScrollView: View {
    @ObservedObject private var PSM = PreferencesStorageModel.shared
    let video: YTVideoWithData
    let geometry: GeometryProxy
    
    var body: some View {
        Group {
            let isHalfThumbnail = PSM.videoViewMode == .halfThumbnail || video.data.videoViewMode == .halfThumbnail
            // Big thumbnail view by default
            VideoFromSearchView(videoWithData: video)
                .frame(width: geometry.size.width, height: isHalfThumbnail ? 180 : geometry.size.width * 9/16 + 90, alignment: .center)
        }
    }
}
