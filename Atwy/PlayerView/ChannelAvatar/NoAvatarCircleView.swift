//
//  NoAvatarCircleView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 18.04.2024.
//  Copyright © 2024-2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation
import SwiftUI

struct NoAvatarCircleView: View {
    let makeGradient: (UIImage) -> Void
    var body: some View {
        UnknownAvatarView()
            .task {
                let renderer = ImageRenderer(content: UnknownAvatarView())
                if let uiImage = renderer.uiImage {
                    makeGradient(uiImage)
                }
            }
    }
}
