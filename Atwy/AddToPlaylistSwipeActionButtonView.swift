//
//  AddToPlaylistSwipeActionButtonView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 19.02.23.
//

import SwiftUI
import YouTubeKit

struct AddToPlaylistSwipeActionButtonView: View {
    @State var video: YTVideo
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
