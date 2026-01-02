//
//  DeleteFromFavoritesView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 23.01.23.
//  Copyright © 2023-2026 Antoine Bollengier. All rights reserved.
//

import SwiftUI
import CoreData
import YouTubeKit

struct DeleteFromFavoritesView: View {
    let video: YTVideo
    var body: some View {
        Button(role: .destructive) {
            Task {
                PersistenceModel.shared.removeFromFavorites(video: video)
            }
        } label: {
            HStack {
                Text("Remove Favorite")
                Image(systemName: "trash")
            }
            .tint(.red)
        }
    }
}
