//
//  AvatarCircleView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 18.04.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation
import SwiftUI

struct AvatarCircleView: View {
    let image: UIImage
    let makeGradient: (UIImage) -> Void
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .clipShape(Circle())
            .task {
                DispatchQueue.main.async {
                    makeGradient(image)
                }
            }
            .id(image)
    }
}
