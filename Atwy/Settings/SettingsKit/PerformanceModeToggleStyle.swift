//
//  PerformanceModeToggleStyle.swift
//  Atwy
//
//  Created by Antoine Bollengier on 18.07.2024.
//  Copyright © 2024-2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI

struct PerformanceModeToggleStyle: ToggleStyle {
    let geometry: GeometryProxy
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .foregroundStyle(.ultraThickMaterial)
            HStack {
                if !configuration.isOn {
                    Spacer()
                }
                RoundedRectangle(cornerRadius: 10)
                    .foregroundStyle(.orange)
                    .frame(width: geometry.size.width * 0.28, height: geometry.size.height * 0.08)
                    .padding(.horizontal)
                if configuration.isOn {
                    Spacer()
                }
            }
            HStack {
                HStack {
                    Spacer()
                    Text("Full")
                    Image(systemName: "hare.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25, height: 25)
                    Spacer()
                }
                .onTapGesture {
                    withAnimation(.spring) {
                        configuration.$isOn.wrappedValue = true
                    }
                }
                Spacer()
                HStack {
                    Spacer()
                    Text("Limited")
                    Image(systemName: "tortoise.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25, height: 25)
                    Spacer()
                }
                .onTapGesture {
                    withAnimation(.spring) {
                        configuration.$isOn.wrappedValue = false
                    }
                }
            }
        }
        .frame(width: 300, height: 75)
        .centered()
    }
}
