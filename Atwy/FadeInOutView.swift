//
//  FadeInOutView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 06.03.2025.
//  Copyright © 2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI

struct FadeInOutView: View {
        let mode: FadeMode
        var gradientSize: CGFloat = 15
        var body: some View {
            switch mode {
            case .horizontal:
                HStack(spacing: 0) {
                    
                    // Left gradient
                    LinearGradient(gradient:
                                    Gradient(
                                        colors: [Color.black.opacity(0), Color.black]),
                                   startPoint: .leading, endPoint: .trailing
                    )
                    .frame(width: gradientSize)
                    
                    // Middle
                    Rectangle().fill(Color.black)
                    
                    // Right gradient
                    LinearGradient(gradient:
                                    Gradient(
                                        colors: [Color.black, Color.black.opacity(0)]),
                                   startPoint: .leading, endPoint: .trailing
                    )
                    .frame(width: gradientSize)
                }
            case .vertical:
                VStack(spacing: 0) {
                    
                    // Top gradient
                    LinearGradient(gradient:
                                    Gradient(
                                        colors: [Color.black.opacity(0), Color.black]),
                                   startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: gradientSize)
                    
                    // Middle
                    Rectangle().fill(Color.black)
                    
                    // Bottom gradient
                    LinearGradient(gradient:
                                    Gradient(
                                        colors: [Color.black, Color.black.opacity(0)]),
                                   startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: gradientSize)
                }
            }
        }
        
        enum FadeMode {
            case horizontal
            case vertical
        }
    }
