//
//  ShareButtonView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 05.12.2024.
//  Copyright © 2024-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI

struct ShareButtonView: View {
    let onTap: () -> Void
    
    var body: some View {
        Button {
            self.onTap()
        } label: {
            Image(systemName: "square.and.arrow.up")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .contentShape(Rectangle())
                .foregroundStyle(Color.accentColor)
        }
        .buttonStyle(.plain)
    }
}
