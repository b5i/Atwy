//
//  CustomSettingToggle.swift
//  Atwy
//
//  Created by Antoine Bollengier on 18.07.2024.
//  Copyright © 2024-2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI

struct CustomSettingToggle<TStyle>: SettingAction where TStyle: ToggleStyle {
    init(title: String, binding: Binding<Bool>, toggleStyle: TStyle = .automatic) {
        self.title = title
        self.toggleStyle = toggleStyle
        self._binding = binding
    }
    
    let title: String
    
    private let toggleStyle: TStyle
    
    @Binding private var binding: Bool
    
    var body: some View {
        Toggle(title, isOn: $binding)
            .toggleStyle(toggleStyle)
    }
}
