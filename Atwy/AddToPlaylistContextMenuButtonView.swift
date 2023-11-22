//
//  AddToPlaylistContextMenuButtonView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 10.02.23.
//

import SwiftUI
import YouTubeKit

struct AddToPlaylistContextMenuButtonView: View {
    let video: YTVideo
    var body: some View {
        Button {
            SheetsModel.shared.showSheet(.addToPlaylist, data: video)
        } label: {
            HStack {
                Text("Add to playlist")
                Image(systemName: "plus.circle")
            }
        }
    }
}
