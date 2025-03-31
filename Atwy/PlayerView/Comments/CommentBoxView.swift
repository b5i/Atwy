//
//  CommentBoxView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 31.03.2025.
//  Copyright © 2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI

struct CommentBoxView<Content: View>: View {
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack {
            content()
        }
        .padding()
        .clipped()
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.gray.gradient)
                .opacity(0.5)
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(style: .init(lineWidth: 2))
                .foregroundStyle(Color(cgColor: .init(red: 0.7, green: 0.7, blue: 0.7, alpha: 1)))
                .opacity(0.5)
        }
        .padding(.horizontal)
    }
}
