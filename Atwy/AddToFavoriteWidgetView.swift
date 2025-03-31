//
//  AddToFavoriteWidgetView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 19.11.2023.
//  Copyright © 2023-2025 Antoine Bollengier. All rights reserved.
//

import SwiftUI
import YouTubeKit

struct AddToFavoriteWidgetView: View {
    let video: YTVideo
    
    @ObservedObject private var PM = PersistenceModel.shared
    var body: some View {
        let isFavorite = PM.checkIfFavorite(video: video)
        
        Image(systemName: isFavorite ? "star.fill" : "star")
            .resizable()
            .scaledToFit()
            .frame(width: 22)
            .foregroundStyle(.white)
    }
}
