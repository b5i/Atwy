//
//  ShowSettingsButton.swift
//  Atwy
//
//  Created by Antoine Bollengier on 22.10.2023.
//

import Foundation
import SwiftUI

public struct ShowSettingsButton: ToolbarContent {
    @ObservedObject private var NRM = NetworkReachabilityModel.shared
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

