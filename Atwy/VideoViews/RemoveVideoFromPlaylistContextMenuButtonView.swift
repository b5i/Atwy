//
//  RemoveVideoFromPlaylistContextMenuButtonView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 09.05.2024.
//  Copyright © 2024-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI
import YouTubeKit

struct RemoveVideoFromPlaylistContextMenuButtonView: View {
    let removalCallBack: () -> ()
    var body: some View {
        Button(role: .destructive) {
            Task {
                removalCallBack()
            }
        } label: {
            HStack {
                Text("Remove from playlist")
                Image(systemName: "trash")
            }
        }
        .tint(.red)
    }
}
