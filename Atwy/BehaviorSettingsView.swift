//
//  BehaviorSettingsView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 03.01.2024.
//

import SwiftUI

struct BehaviorSettingsView: View {
    @ObservedObject private var PSM = PreferencesStorageModel.shared
    
    @State private var performanceChoice: PreferencesStorageModel.Properties.PerformanceModes
    
    init() {
        /// Maybe using AppStorage would be better
        if let state = PreferencesStorageModel.shared.propetriesState[.performanceMode] as? PreferencesStorageModel.Properties.PerformanceModes {
            self._performanceChoice = State(wrappedValue: state)
        } else {
            self._performanceChoice = State(wrappedValue: .full)
        }
    }
    var body: some View {
        GeometryReader { geometry in
            List {
                Section("Performance Mode") {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundStyle(.ultraThickMaterial)
                        HStack {
                            if performanceChoice == .limited {
                                Spacer()
                            }
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundStyle(.orange)
                                .frame(width: geometry.size.width * 0.28, height: geometry.size.height * 0.08)
                                .padding(.horizontal)
                            if performanceChoice != .limited {
                                Spacer()
                            }
                        }
                        HStack {
                            HStack {
                                Spacer()
                                Text("Full")
                                Image(systemName: "hare.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 25, height: 25)
                                Spacer()
                            }
                            .onTapGesture {
                                withAnimation(.spring) {
                                    performanceChoice = .full
                                    PSM.setNewValueForKey(.performanceMode, value: PreferencesStorageModel.Properties.PerformanceModes.full)
                                }
                            }
                            Spacer()
//                            RoundedRectangle(cornerRadius: 50)
//                                .frame(width: 2)
//                                .foregroundStyle(.thickMaterial)
//                                .padding(.vertical)
//                            Spacer()
                            HStack {
                                Spacer()
                                Text("Limited")
                                Image(systemName: "tortoise.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 25, height: 25)
                                Spacer()
                            }
                            .onTapGesture {
                                withAnimation(.spring) {
                                    performanceChoice = .limited
                                    PSM.setNewValueForKey(.performanceMode, value: PreferencesStorageModel.Properties.PerformanceModes.limited)
                                }
                            }
                        }
                    }
                    .frame(width: geometry.size.width * 0.7, height: geometry.size.height * 0.10)
                    .centered()
                    Text("Enabling the limited performance mode will use less CPU and RAM while using the app. It will use other UI components that could make your experience a bit more laggy if the app was working smoothly before but it could make it more smooth if the app was very laggy before.")
                        .foregroundStyle(.gray)
                        .font(.caption)
                }
                .onAppear {
                    if let state = PreferencesStorageModel.shared.propetriesState[.performanceMode] as? PreferencesStorageModel.Properties.PerformanceModes {
                        self.performanceChoice = state
                    } else {
                        self.performanceChoice = .full
                    }
                }
            }
        }
    }
}
