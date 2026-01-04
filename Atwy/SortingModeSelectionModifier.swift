//
//  SortingModeSelectionModifier.swift
//  Atwy
//
//  Created by Antoine Bollengier on 28.03.2024.
//  Copyright © 2024-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI

struct SortingModeSelectionModifier: ViewModifier {
    typealias SortingModes = PreferencesStorageModel.Properties.SortingModes
    
    let sortingMode: ReferenceWritableKeyPath<PreferencesStorageModel, PreferencesStorageModel.SortingModes>
    
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var PSM = PreferencesStorageModel.shared

    func body(content: Content) -> some View {
        content
            .toolbar(content: {
                ToolbarItem(placement: .topBarTrailing, content: {
                    Menu {
                        let selectionBinding: Binding<PreferencesStorageModel.Properties.SortingModes> = Binding(get: {
                            PSM[keyPath: self.sortingMode]
                        }, set: { newValue in
                            PSM[keyPath: self.sortingMode] = newValue
                        })
                        Picker("", selection: selectionBinding) {
                            Label("Newest", systemImage: "arrow.up.to.line.compact").tag(PreferencesStorageModel.Properties.SortingModes.newest)
                            Label("Oldest", systemImage: "arrow.down.to.line.compact").tag(PreferencesStorageModel.Properties.SortingModes.oldest)
                            Label("Title", systemImage: "play.rectangle").tag(PreferencesStorageModel.Properties.SortingModes.title)
                            Label("Channel", systemImage: "person").tag(PreferencesStorageModel.Properties.SortingModes.channelName)
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(colorScheme.textColor == .white ? .white.opacity(0.1) : .black.opacity(0.35))
                                .frame(width: 30)
                            Circle()
                                .fill(.regularMaterial)
                                .frame(width: 30)
                            Image(systemName: "line.3.horizontal.decrease") // or arrow.up.and.down.text.horizontal arrow.up.arrow.down.circle
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18)
                        }
                    }
                })
            })
    }
}

extension View {
    /// Add a button to the top trailing toolbar to change the sort mode for the desired ``PreferencesStorageModel.Properties``, should be ``PreferencesStorageModel/Properties/favoritesSortingMode`` or ``PreferencesStorageModel/Properties/downloadsSortingMode``.
    func sortingModeSelectorButton(forPropertyPath path: ReferenceWritableKeyPath<PreferencesStorageModel, PreferencesStorageModel.SortingModes>) -> some View {
        self.modifier(SortingModeSelectionModifier(sortingMode: path))
    }
}
