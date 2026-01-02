//
//  SACustomAction.swift
//  Atwy
//
//  Created by Antoine Bollengier on 18.07.2024.
//  Copyright © 2024-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI

struct SACustomAction<ActionView>: SettingAction where ActionView: View {
    let title: String
    
    @ViewBuilder let actionView: ActionView
    
    var body: some View {
        actionView
    }
}
