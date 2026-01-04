//
//  StorageSettingsView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 01.12.2023.
//  Copyright © 2023-2026 Antoine Bollengier. All rights reserved.
//

import SwiftUI
import OSLog

struct StorageSettingsView: View {
    @State private var isDeletingCoreSpotlight: Bool = false
    var body: some View {
        SettingsMenu(title: "Storage", sections: { _ in
            SettingsSection(title: "Search History") {
                Setting(textDescription: nil, action: try! SAToggle(PSMType: .searchHistoryEnabled, title: "Enable Search History").setAction { newValue in
                    if !newValue {
                        PersistenceModel.shared.removeSearchHistory()
                    }
                    return newValue
                })
            }
            SettingsSection(title: "Watch History") {
                Setting(textDescription: "Enabling Watch History will make the player save the progress of watched videos locally and show a red line indicating the watched amount of the video. Will also take the value from YouTube if it's available.", action: try! SAToggle(PSMType: .watchHistoryEnabled, title: "Watch History"))
                Setting(textDescription: "Delete all the local watch history, may need app restart to apply.", action: SATextButton(title: "Reset Local Watch History", buttonLabel: "Reset", action: { _ in
                    PersistenceModel.shared.resetLocalWatchHistory()
                }))
            }
            SettingsSection(title: "Spotlight", settings: {
                Setting(textDescription: nil, action: SATextButton(title: "Reset CoreSpotlight indexing", buttonLabel: "Reset", action: { showHideButton in
                    showHideButton(false)
                    PersistenceModel.shared.controller.spotlightIndexer?.deleteSpotlightIndex(completionHandler: { error in
                        if let error = error {
                            Logger.atwyLogs.simpleLog("\(error.localizedDescription)")
                        }
                        DispatchQueue.main.async {
                            showHideButton(true)
                        }
                    })
                }))
            })
            // Is it still useful?
            SettingsSection(title: "Keychain", settings: {
                Setting(textDescription: "Force remove the cookies from the Keychain, can be useful if you can't connect your account (the button does nothing). This button has the same effect as the \"unlink account\" button when an account is connected.", action: SATextButton(title: "Remove cookies", buttonLabel: "Remove", action: { _ in
                    APIKeyModel.shared.deleteAccount()
                }))
            })
        })
    }
}
