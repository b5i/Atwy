//
//  VideoInScrollView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 08.07.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI

struct VideoInScrollView: View {
    @ObservedObject private var PSM = PreferencesStorageModel.shared
    let video: YTVideoWithData
    let geometry: GeometryProxy
    
    var body: some View {
        Group {
            if let state = PSM.propetriesState[.videoViewMode] as? PreferencesStorageModel.Properties.VideoViewModes, state == .halfThumbnail {
                VideoFromSearchView(videoWithData: video)
                    .frame(width: geometry.size.width, height: 180, alignment: .center)
            } else if video.data.videoViewMode == .halfThumbnail {
                VideoFromSearchView(videoWithData: video)
                    .frame(width: geometry.size.width, height: 180, alignment: .center)
            } else {
                // Big thumbnail view by default
                VideoFromSearchView(videoWithData: video)
                    .frame(width: geometry.size.width, height: geometry.size.width * 9/16 + 90, alignment: .center)
                //                                            .padding(.bottom, resultIndex == 0 ? geometry.size.height * 0.2 : 0)
            }
        }
    }
}
