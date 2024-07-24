//
//  BehaviorSettingsView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 03.01.2024.
//

import SwiftUI

struct BehaviorSettingsView: View {
    var body: some View {
        SettingsMenu(title: "Behavior") { geometry in
            SettingsSection(title: "Performance Mode") {
                Setting(textDescription: "Enabling the limited performance mode will use less CPU and RAM while using the app. It will use other UI components that could make your experience a bit more laggy if the app was working smoothly before but it could make it more smooth if the app was very laggy before.", action: try! SAToggle(PSMType: .performanceModeEnabled, title: "", toggleStyle: PerformanceModeToggleStyle(geometry: geometry)))
            }
            SettingsSection(title: "Live activities", settings: {
                Setting(textDescription: "Enabling Live Activities will show a Live Activity giving informations on the current downloadings.", action: try! SAToggle(PSMType: .liveActivitiesEnabled, title: "Live activities").setAction { newValue in
                    if #available(iOS 16.1, *) {
                        if PreferencesStorageModel.shared.liveActivitiesEnabled, !newValue {
                            DownloadingsProgressActivity.stop()
                        } else if !PreferencesStorageModel.shared.liveActivitiesEnabled, newValue, DownloadersModel.shared.activeDownloaders.count != 0 {
                            DownloadingsProgressActivity.setupOnManager(attributes: .init(), state: .modelState)
                        }
                    }
                    return newValue
                })
            }, hidden: {if #available(iOS 16.1, *) { false } else { true }}())
            SettingsSection(title: "Downloads") {
                Setting(textDescription: nil, action: try! SAStepper(valueType: Int.self, PSMType: .concurrentDownloadsLimit, title: "Concurrent Downloads Limit").setAction { let newValue = max(1, $0); DownloadersModel.shared.maxConcurrentDownloadsChanged(newValue); return newValue })
            }
            SettingsSection(title: "Picture in Picture") {
                Setting(textDescription: "Enabling automatic Picture in Picture (PiP) will switch to PiP when put the app in background but don't quit it, while playing a video. If the player is playing an audio-only asset the PiP will never launch.", action: try! SAToggle(PSMType: .automaticPiP, title: "Automatic PiP"))
            }
            SettingsSection(title: "Background playback") {
                Setting(textDescription: "Enabling background playback will make the player continue playing the video/audio when you quit the app or shut down the screen. If automatic PiP is enabled, it will be preferred over simple background playback when quitting the app.", action: try! SAToggle(PSMType: .backgroundPlayback, title: "Background playback"))
            }
        }
    }
}
