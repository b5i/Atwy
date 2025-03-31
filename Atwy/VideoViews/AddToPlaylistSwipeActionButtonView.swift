//
//  AddToPlaylistSwipeActionButtonView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 19.02.23.
//  Copyright © 2023-2025 Antoine Bollengier. All rights reserved.
//

import SwiftUI
import YouTubeKit

struct AddToPlaylistSwipeActionButtonView: View {
    let video: YTVideo
    var body: some View {
        Button {
            SheetsModel.shared.showSheet(.addToPlaylist, data: video)
        } label: {
            ZStack {
                Rectangle()
                    .tint(.green)
                Image(systemName: "text.badge.plus")
                    .tint(.white)
            }
        }
        .tint(.green)
    }
}
