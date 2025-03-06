//
//  AddToFavoriteWidgetView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 19.11.2023.
//

import SwiftUI
import YouTubeKit

struct AddToFavoriteWidgetView: View {
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
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .foregroundStyle(.ultraThinMaterial)
                    .preferredColorScheme(.light)
                    .frame(height: 45)
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22)
                    .foregroundStyle(.white)
            }
        }
    }
}
