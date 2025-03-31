//
//  SATextButton.swift
//  Atwy
//
//  Created by Antoine Bollengier on 18.07.2024.
//  Copyright © 2024-2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI

struct SATextButton: SettingAction {
    let title: String
    
    let buttonLabel: String
    
    let action: (_ showHideButton: @escaping (Bool) -> Void) -> Void
    
    @State private var showButton: Bool = true
            
    var body: some View {
        HStack {
            if !title.isEmpty {
                Text(title)
                Spacer()
            }
            
            if showButton {
                Button(buttonLabel, action: {
                    action { self.showButton = $0 }
                })
            } else {
                ProgressView()
            }
        }
    }
}
