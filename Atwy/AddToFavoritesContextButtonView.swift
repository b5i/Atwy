//
//  AddToFavoritesContextButtonView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 22.01.23.
//

import SwiftUI
import YouTubeKit

struct AddToFavoritesContextButtonView: View {
    @State var video: YTVideo
    @State var imageData: Data?
    var body: some View {
        Button {
            PersistenceModel.shared.addToFavorites(
                video: video,
                imageData: imageData
            )
        } label: {
            HStack {
                Text("Add to favorites")
                Image(systemName: "star.fill")
            }
        }
    }
}
