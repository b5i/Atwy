//
//  View+optionalRefreshable.swift
//  Atwy
//
//  Created by Antoine Bollengier on 08.07.2024.
//  Copyright © 2024-2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI

extension View {
    func optionalRefreshable(_ action: (@Sendable () async -> Void)?) -> some View {
        Group {
            if let action = action {
                self.refreshable(action: action)
            } else {
                self
            }
        }
    }
}
