//
//  PrivateAPIsSettingsView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 08.04.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI

struct PrivateAPIsSettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var PSM = PreferencesStorageModel.shared
    
    @State private var customAVButtons: Bool
    
    init() {
        /// Maybe using AppStorage would be better
        if let state = PreferencesStorageModel.shared.propetriesState[.customAVButtonsEnabled] as? Bool {
            self._customAVButtons = State(wrappedValue: state)
        } else {
            self._customAVButtons = State(wrappedValue: false)
        }
    }
    var body: some View {
        GeometryReader { geometry in
            List {
                VStack(alignment: .leading) {
                    Text("Warning")
                        .foregroundStyle(.red)
                    Text("Enabling Private APIs may make your device crash unexpectedly, make sure to disable any activated Private API before submitting a crash report.")
                }
                .listRowBackground(Color.red.opacity(0.2))
                Section("Private APIs") {
                    VStack {
                        let cacheLimitEnabledBinding: Binding<Bool> = Binding(get: {
                            self.customAVButtons
                        }, set: { newValue in
                            self.customAVButtons = newValue
                            if newValue {
                                PrivateManager.shared.avButtonsManager?.inject()
                            } else {
                                PrivateManager.shared.avButtonsManager?.removeInjection()
                            }
                        })
                        Toggle(isOn: cacheLimitEnabledBinding, label: {
                            Text("Custom Player Buttons")
                        })
                        Text("Enabling Custom Player Buttons will show various actions such as like/dislike to the video player full-screen view.")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .disabled(PrivateManager.shared.avButtonsManager == nil)
                }
            }
            .onAppear {
                if let state = PreferencesStorageModel.shared.propetriesState[.customAVButtonsEnabled] as? Bool {
                    self.customAVButtons = state
                } else {
                    self.customAVButtons = false
                }
            }
        }
        .navigationTitle("Private APIs")
    }
}
