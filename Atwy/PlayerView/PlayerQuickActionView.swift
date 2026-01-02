//
//  PlayerQuickActionView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 06.03.2025.
//  Copyright © 2025-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI

struct PlayerQuickActionView<Label: View>: View {
    @ViewBuilder let label: () -> Label
    let action: () -> Void
    
    var body: some View {
        Button(action: action, label: {
            label()
                .padding(.horizontal, 20)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundStyle(.ultraThinMaterial)
                        .preferredColorScheme(.light)
                        .frame(height: 45)
                }
        })
        .padding(.horizontal, 5)
    }
}
