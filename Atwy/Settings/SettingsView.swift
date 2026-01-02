//
//  SettingsView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 26.11.22.
//  Copyright © 2022-2026 Antoine Bollengier. All rights reserved.
//

import SwiftUI
import Security
import AVKit

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var APIM = APIKeyModel.shared
    @ObservedObject private var NPM = NavigationPathModel.shared
    @ObservedObject private var NM = NetworkReachabilityModel.shared
    @State private var showingConfirmation: Bool = false
    @State private var showInstructions: Bool = true
    var body: some View {
        NavigationStack(path: $NPM.settingsSheetPath) {
            ScrollView {
                VStack {
                    if !NM.connected {
                        VStack(alignment: .center) {
                            Image(systemName: "wifi.slash")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30)
                                .padding(.top)
                            Text("You are disconnected.")
                                .font(.caption)
                            Text("Disable the flight mode or connect to a WiFi to view Account settings.")
                                .foregroundStyle(.gray)
                                .font(.caption2)
                        }
                    } else if let account = APIM.userAccount, account.name != nil {
                        UserPreferenceCircleView()
                            .frame(width: 100, height: 100)
                            .padding(.top)
                        VStack {
                            Text(account.name ?? "")
                                .font(.title2)
                                .bold()
                            Text(account.channelHandle ?? "")
                                .font(.footnote)
                                .bold()
                                .foregroundColor(.gray)
                            
                            HStack {
                                Text("Unlink account")
                                Image(systemName: "minus.circle")
                                    .frame(width: 30, height: 30)
                            }
                            .foregroundColor(.red)
                            .onTapGesture {
                                showingConfirmation = true
                            }
                            .confirmationDialog("Unlink account?", isPresented: $showingConfirmation) {
                                Button("Yes", role: .destructive) {
                                    APIM.deleteAccount()
                                }
                                Button("Cancel", role: .cancel) { }
                            } message: {
                                Text("Unlink confirmation")
                            }
                            .padding(.top)
                        }
                    } else if APIM.isFetchingAccountInfos {
                        LoadingView(customText: "account infos")
                    } else {
                        VStack {
                            HStack {
                                Text("Connect your YouTube account")
                                Image(systemName: "plus.circle")
                                    .frame(width: 30, height: 30)
                            }
                            .routeTo(.googleConnection)
                        }
                        .padding()
                    }
                    List {
                        SettingsEntry(
                            iconName: "doc.questionmark.fill",
                            iconColor: .white,
                            iconBackgroundColor: .green,
                            title: "Behavior",
                            routeTo: .behaviorSettings)
                        SettingsEntry(
                            iconName: "textformat.size",
                            iconColor: .white,
                            iconBackgroundColor: .blue,
                            title: "Appeareance",
                            routeTo: .appearanceSettings)
                        SettingsEntry(
                            iconName: "gear",
                            iconColor: .white,
                            iconBackgroundColor: .gray,
                            title: "Storage",
                            routeTo: .storageSettings)
                        SettingsEntry(
                            iconName: "list.bullet.rectangle",
                            iconColor: .black,
                            iconBackgroundColor: .yellow,
                            title: "Console",
                            routeTo: .consoleSettings)
                        SettingsEntry(
                            iconName: "list.bullet.clipboard",
                            iconColor: .white,
                            iconBackgroundColor: .red,
                            title: "YouTubeKit Logger",
                            routeTo: .loggerSettings)
                        SettingsEntry(
                            iconName: "exclamationmark.triangle.fill",
                            iconColor: .yellow,
                            iconBackgroundColor: .black,
                            title: "Private APIs",
                            routeTo: .privateAPIsSettings)
                        SettingsEntry(
                            iconName: "book.fill",
                            iconColor: .white,
                            iconBackgroundColor: .orange,
                            title: "Licenses",
                            routeTo: .licensesSettings)
                    }
                    .frame(height: 360)
                }
            }
            .routeContainer()
            .navigationTitle("Settings")
            #if os(macOS)
            .toolbar(content: {
                ToolbarItem(placement: .secondaryAction, content: {
                    Button {
                        dismiss()
                    } label: {
                        Text("OK")
                            .bold()
                    }
                })
            })
            #else
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing, content: {
                    Button {
                        dismiss()
                    } label: {
                        Text("OK")
                            .bold()
                    }
                })
            })
            #endif
        }
    }
}

#Preview {
    SettingsView()
}
