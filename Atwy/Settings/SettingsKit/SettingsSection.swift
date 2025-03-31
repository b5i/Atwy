//
//  SettingsSection.swift
//  Atwy
//
//  Created by Antoine Bollengier on 18.07.2024.
//  Copyright © 2024-2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI

struct SettingsSection: View {
    let title: String
    
    @SettingsSectionBuilder let settings: () -> [Setting]
    
    var hidden: Bool = false
    
    var body: some View {
        if hidden {
            EmptyView()
        } else {
            Section(title) {
                ForEach(Array(settings().enumerated()), id: \.offset) { (_, setting) in
                    AnyView(setting)
                }
            }
        }
    }
}
