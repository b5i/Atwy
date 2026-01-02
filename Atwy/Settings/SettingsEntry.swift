//
//  SettingsEntry.swift
//  Atwy
//
//  Created by Antoine Bollengier on 05.12.2024.
//  Copyright © 2024-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI

struct SettingsEntry: View {
    let iconName: String
    let iconColor: Color
    let iconBackgroundColor: Color
    
    let title: String
    let routeTo: RouteDestination
    
    var body: some View {
        Group {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundColor(iconBackgroundColor)
                    Image(systemName: iconName)
                        .foregroundColor(iconColor)
                }
                .frame(width: 30, height: 30)
            }
            Text(title)
            Spacer()
        }
        .routeTo(routeTo)
    }
}
