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
    @State private var variableBlur: Bool
    @State private var customSearchBar: Bool
    
    init() {
        /// Maybe using AppStorage would be better
        if let state = PreferencesStorageModel.shared.propetriesState[.customAVButtonsEnabled] as? Bool {
            self._customAVButtons = State(wrappedValue: state)
        } else {
            let defaultMode = PreferencesStorageModel.Properties.customAVButtonsEnabled.getDefaultValue() as? Bool ?? true
            self._customAVButtons = State(wrappedValue: defaultMode)
        }
        
        if let state = PreferencesStorageModel.shared.propetriesState[.variableBlurEnabled] as? Bool {
            self._variableBlur = State(wrappedValue: state)
        } else {
            let defaultMode = PreferencesStorageModel.Properties.variableBlurEnabled.getDefaultValue() as? Bool ?? true
            self._variableBlur = State(wrappedValue: defaultMode)
        }
        
        if let state = PreferencesStorageModel.shared.propetriesState[.customSearchBarEnabled] as? Bool {
            self._customSearchBar = State(wrappedValue: state)
        } else {
            let defaultMode = PreferencesStorageModel.Properties.customSearchBarEnabled.getDefaultValue() as? Bool ?? true
            self._customSearchBar = State(wrappedValue: defaultMode)
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
                Section("Video Player") {
                    VStack {
                        let customAVButtonsEnabledBinding: Binding<Bool> = Binding(get: {
                            if PrivateManager.shared.avButtonsManager == nil {
                                return false
                            } else {
                                return self.customAVButtons
                            }
                        }, set: { newValue in
                            guard PrivateManager.shared.avButtonsManager != nil else { return }
                            self.customAVButtons = newValue
                            if newValue {
                                PrivateManager.shared.avButtonsManager?.inject()
                            } else {
                                PrivateManager.shared.avButtonsManager?.removeInjection()
                            }
                        })
                        Toggle(isOn: customAVButtonsEnabledBinding, label: {
                            Text("Custom Player Buttons")
                        })
                        Text("Enabling Custom Player Buttons will show various actions such as like/dislike to the video player full-screen view.")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .fixedSize(horizontal: false, vertical: true)
                        if PrivateManager.shared.avButtonsManager == nil {
                            Label("Private APIs checks have failed for this option, therefore you can't enable it for safety reasons.", systemImage: "exclamationmark.triangle.fill")
                                .labelStyle(FailedInitPrivateAPILabelStyle())
                        }
                    }
                    .disabled(PrivateManager.shared.avButtonsManager == nil)
                }
                Section("Variable Blur") {
                    VStack {
                        let variableBlurEnabledBinding: Binding<Bool> = Binding(get: {
                            if PrivateManager.shared.isVariableBlurAvailable {
                                return self.variableBlur
                            } else {
                                return false
                            }
                        }, set: { newValue in
                            guard PrivateManager.shared.isVariableBlurAvailable else { return }
                            self.variableBlur = newValue
                            DispatchQueue.main.async {
                                PreferencesStorageModel.shared.setNewValueForKey(.variableBlurEnabled, value: newValue)
                            }
                        })
                        Toggle(isOn: variableBlurEnabledBinding, label: {
                            Text("Variable Blur")
                        })
                        Text("Enabling Variable Blur enhances the experience in various UI elements of Atwy such as the Video Player.")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .fixedSize(horizontal: false, vertical: true)
                        if !PrivateManager.shared.isVariableBlurAvailable {
                            Label("Private APIs checks have failed for this option, therefore you can't enable it for safety reasons.", systemImage: "exclamationmark.triangle.fill")
                                .labelStyle(FailedInitPrivateAPILabelStyle())
                        }
                    }
                    .disabled(!PrivateManager.shared.isVariableBlurAvailable)
                }
                Section("Search Menu", content: {
                    let customSearchMenuEnabledBinding: Binding<Bool> = Binding(get: {
                        if PrivateManager.shared.isCustomSearchMenuAvailable {
                            return self.customSearchBar
                        } else {
                            return false
                        }
                    }, set: { newValue in
                        guard PrivateManager.shared.isCustomSearchMenuAvailable else { return }
                        self.customSearchBar = newValue
                        DispatchQueue.main.async {
                            PreferencesStorageModel.shared.setNewValueForKey(.customSearchBarEnabled, value: newValue)
                        }
                    })
                    VStack {
                        Toggle(isOn: customSearchMenuEnabledBinding, label: {
                            Text("Custom Search Menu")
                        })
                        Text("Enabling Custom Search Menu brings a great search experience to the app. \(Text("Changing this option might require to restart the app in order for it to work.").bold())")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    VStack {
                        HStack {
                            Text("Reset Search Textfield Location")
                            Spacer()
                            Button {
                                PreferencesStorageModel.shared.setNewValueForKey(.searchBarHeight, value: nil)
                                TopSearchBarController.searchBarHeight = nil
                            } label: {
                                Text("Reset")
                            }
                        }
                        Text("Resetting the Search Textfield Location might help fix the transition to the Search Menu if it's broken.")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .fixedSize(horizontal: false, vertical: true)
                        if !PrivateManager.shared.isCustomSearchMenuAvailable {
                            Label("Private APIs checks have failed for this option, therefore you can't enable it for safety reasons.", systemImage: "exclamationmark.triangle.fill")
                                .labelStyle(FailedInitPrivateAPILabelStyle())
                        }
                    }
                })
                .disabled(!PrivateManager.shared.isCustomSearchMenuAvailable)
            }
            .onAppear {
                if let state = PreferencesStorageModel.shared.propetriesState[.customAVButtonsEnabled] as? Bool {
                    self.customAVButtons = state
                } else {
                    self.customAVButtons = PreferencesStorageModel.Properties.customAVButtonsEnabled.getDefaultValue() as? Bool ?? true
                }
                
                if let state = PreferencesStorageModel.shared.propetriesState[.variableBlurEnabled] as? Bool {
                    self.variableBlur = state
                } else {
                    self.variableBlur = PreferencesStorageModel.Properties.variableBlurEnabled.getDefaultValue() as? Bool ?? true
                }
                
                if let state = PreferencesStorageModel.shared.propetriesState[.customSearchBarEnabled] as? Bool {
                    self.customSearchBar = state
                } else {
                    self.customSearchBar = PreferencesStorageModel.Properties.customSearchBarEnabled.getDefaultValue() as? Bool ?? true
                }
            }
        }
        .navigationTitle("Private APIs")
    }
}

#Preview {
    PrivateAPIsSettingsView()
}
