//
//  ThumbnailPlaceholderView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 30.03.2025.
//  Copyright © 2025-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI

struct RoundedThumbnailPlaceholderView: View {
    var body: some View {
        ZStack {
            Circle()
                .foregroundStyle(.ultraThinMaterial)
            ProgressView()
        }
    }
}

struct RectangularThumbnailPlaceholderView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .foregroundStyle(.ultraThinMaterial)
                .aspectRatio(16/9, contentMode: .fit)
            ProgressView()
        }
    }
}
