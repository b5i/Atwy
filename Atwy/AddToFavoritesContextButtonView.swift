//
//  AddToFavoritesContextButtonView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 22.01.23.
//

import SwiftUI
import YouTubeKit

struct AddToFavoritesContextButtonView: View, Equatable {
    let video: YTVideo
    let imageData: Data?
    var body: some View {
        Button {
            Task {
                PersistenceModel.shared.addToFavorites(
                    video: video,
                    imageData: imageData
                )
            }
        } label: {
            HStack {
                Text("Add to favorites")
                Image(systemName: "star.fill")
            }
        }
    }
}
