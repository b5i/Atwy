//
//  LazyStack.swift
//  Atwy
//
//  Created by Antoine Bollengier on 08.07.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI

struct LazyStack<Content: View>: View {
    let orientation: Axis
    let content: () -> Content
    
    init(orientation: Axis, @ViewBuilder content: @escaping () -> Content) {
        self.orientation = orientation
        self.content = content
    }
    
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
