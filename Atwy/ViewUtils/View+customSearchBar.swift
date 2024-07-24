//
//  View+customSearchBar.swift
//  Atwy
//
//  Created by Antoine Bollengier on 12.07.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import UIKit
import SwiftUI
import Combine
import OSLog

extension View {
    func customSearchBar(text: Binding<String>, onSubmit: @escaping () -> Void) -> some View {
        let textBinding = TextBinding(text: text.wrappedValue, didChangeCallbacks: [{ newValue in
            text.wrappedValue = newValue
        }])
        var localError = false
        do {
            if !PrivateManager.shared.isCustomSearchMenuAvailable {
                throw "Not available."
            } else if !PreferencesStorageModel.shared.customSearchBarEnabled {
                localError = true
                throw "Not enabled."
            }
            
            let controller = try TopSearchBarController(textBinding: textBinding, onSubmit: onSubmit)
            return AnyView(
                self
                    .customHeaderView(controller, shouldShow: { return NetworkReachabilityModel.shared.connected })
                    .onAppear {
                        TopSearchBarController.searchBarHeight = PreferencesStorageModel.shared.searchBarHeight
                    }
            )
        } catch {
            Logger.atwyLogs.simpleLog("Could not initialize customSearchBar, error: \(error.localizedDescription)")
            PrivateManager.shared.isCustomSearchMenuAvailable = localError
            return AnyView(
                self
                    .searchable(text: text, placement: .navigationBarDrawer(displayMode: .always))
            )
        }
    }
}
