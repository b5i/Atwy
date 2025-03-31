//
//  AddToFavoritesButtonView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 14.03.2024.
//  Copyright © 2024-2025 Antoine Bollengier. All rights reserved.
//

import SwiftUI
import YouTubeKit

struct AddToFavoritesButtonView: View {
    let video: YTVideo
    let imageData: Data?
    @ObservedObject private var PM = PersistenceModel.shared
    var body: some View {
        let isFavorite = PM.checkIfFavorite(video: video)
        
        Button {
            if isFavorite {
                PersistenceModel.shared.removeFromFavorites(video: video)
            } else {
                PersistenceModel.shared.addToFavorites(video: video, imageData: imageData)
            }
        } label: {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .resizable()
                .scaledToFit()
                .frame(width: 20)
        }
    }
}
