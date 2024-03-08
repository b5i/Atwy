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
    @State private var observer: (any NSObjectProtocol)? = nil
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
            self.observer = NotificationCenter.default.addObserver(
                forName: .atwyCoreDataChanged,
                object: nil,
                queue: nil,
                using: { _ in
                    reloadCoreData()
                })
        }
        .onDisappear {
            if let observer = self.observer {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
    
    private func reloadCoreData() {
        withAnimation {
            self.isFavorite = PersistenceModel.shared.checkIfFavorite(video: video)
        }
    }
}
