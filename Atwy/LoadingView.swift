//
//  LoadingView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 22.01.23.
//  Copyright © 2023-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//

import SwiftUI

struct LoadingView: View {
    var customText: String? = nil
    var style: LoadingViewStyle = .automatic
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        let loadingTint: Color = {
            switch style {
            case .automatic:
                return colorScheme.textColor
            case .dark:
                return .black
            case .light:
                return .white
            }
        }()
        
        VStack {
            ProgressView()
                .foregroundColor(.gray)
                .padding(.bottom, 0.3)
            Text("LOADING" + ((customText == nil) ? "" : " ") + (customText?.uppercased() ?? "") + "...")
                .foregroundColor(.gray)
                .font(.caption2)
        }
        .frame(width: 160, height: 50)
        .foregroundStyle(loadingTint)
        .tint(loadingTint)
    }
    
    enum LoadingViewStyle {
        case automatic, dark, light
    }
}
