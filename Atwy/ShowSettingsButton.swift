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
            if NRM.connected {
                Button {
                    SheetsModel.shared.showSheet(.settings)
                } label: {
                    UserPreferenceCircleView()
                        .frame(width: 40, height: 40)
                        .padding(.trailing)
                }
            }
        })
#else
        ToolbarItem(placement: .navigationBarTrailing, content: {
            if NRM.connected {
                Button {
                    SheetsModel.shared.showSheet(.settings)
                } label: {
                    UserPreferenceCircleView()
                        .frame(width: 40, height: 40)
                        .padding(.trailing)
                }
            }
        })
#endif
    }
}
