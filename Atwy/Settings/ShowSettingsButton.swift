//
//  ShowSettingsButton.swift
//  Atwy
//
//  Created by Antoine Bollengier on 22.10.2023.
//  Copyright © 2023-2025 Antoine Bollengier. All rights reserved.
//

import Foundation
import SwiftUI

public struct ShowSettingsButton: ToolbarContent {
    public var body: some ToolbarContent {
#if os(macOS)
        ToolbarItem(placement: .secondaryAction, content: {
            ShowSettingsButtonView()
        })
#else
        ToolbarItem(placement: .navigationBarTrailing, content: {
            ShowSettingsButtonView()
        })
#endif
    }
}

