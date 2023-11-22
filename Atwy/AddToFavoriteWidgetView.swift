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
    @State private var isFavorite: Bool = false
    var body: some View {
        Button {
            if isFavorite {
                PersistenceModel.shared.removeFromFavorites(video: video)
            } else {
                PersistenceModel.shared.addToFavorites(video: video, imageData: imageData)
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .foregroundStyle(.white)
                    .opacity(0.3)
                    .frame(height: 45)
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22)
                    .foregroundStyle(.white)
            }
        }
        .onAppear {
            reloadCoreData()
            NotificationCenter.default.addObserver(
                forName: Notification.Name("CoreDataChanged"),
                object: nil,
                queue: nil,
                using: { _ in
                    reloadCoreData()
                })
        }
    }
    
    private func reloadCoreData() {
        withAnimation {
            self.isFavorite = PersistenceModel.shared.checkIfFavorite(video: video)
        }
    }
}
