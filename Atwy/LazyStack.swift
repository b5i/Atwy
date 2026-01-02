//
//  LazyStack.swift
//  Atwy
//
//  Created by Antoine Bollengier on 08.07.2024.
//  Copyright © 2024-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI

struct LazyStack<Content: View>: View {
    let orientation: Axis
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        switch orientation {
        case .horizontal:
            LazyHStack {
                content()
            }
        case .vertical:
            LazyVStack {
                content()
            }
        }
    }
}
