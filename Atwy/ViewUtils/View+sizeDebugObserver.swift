//
//  View+sizeDebugObserver.swift
//  Atwy
//
//  Created by Antoine Bollengier on 06.03.2025.
//  Copyright © 2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI

extension View {
    @ViewBuilder func sizeDebugObserver() -> some View {
        self
            .overlay {
                GeometryReader { geometry in
                    Color.clear.frame(width: 0, height: 0)
                        .onChange(of: geometry.size, perform: { _ in
                            print(geometry.size)
                        })
                        .onAppear {
                            print(geometry.size)
                        }
                }
            }
    }
}
