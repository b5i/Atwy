//
//  SettingAction.swift
//  Atwy
//
//  Created by Antoine Bollengier on 18.07.2024.
//  Copyright © 2024-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI

protocol SettingAction: View {
    associatedtype InternalActionView: View
    
    var title: String { get }
                
    @ViewBuilder var _body: InternalActionView { get }
}

extension SettingAction {
    var _body: some View {
        body
    }
}
