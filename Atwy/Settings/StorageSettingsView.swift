//
//  StorageSettingsView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 01.12.2023.
//

import SwiftUI
import OSLog

struct StorageSettingsView: View {
    @State private var isDeletingCoreSpotlight: Bool = false
    var body: some View {
        VStack {
            List {
                Section("Core Data", content: {
                    HStack {
                        Text("Reset CoreSpotlight indexing")
                        Spacer()
                        if isDeletingCoreSpotlight {
                            ProgressView()
                        } else {
                            Button {
                                isDeletingCoreSpotlight = true
                                PersistenceModel.shared.controller.spotlightIndexer?.deleteSpotlightIndex(completionHandler: { error in
                                    if let error = error {
                                        Logger.atwyLogs.simpleLog("\(error.localizedDescription)")
                                    }
                                    DispatchQueue.main.async {
                                        isDeletingCoreSpotlight = false
                                    }
                                })
                            } label: {
                                Text("Reset")
                            }
                        }
                    }
                })
                Section("Keychain", content: {
                    VStack {
                        HStack {
                            Text("Remove cookies")
                            Spacer()
                            Button("Remove") {
                                APIKeyModel.shared.deleteAccount()
                            }
                        }
                        Text("Force remove the cookies from the Keychain, can be useful if you can't connect your account (the button does nothing). This button has the same effect as the \"unlink account\" button when an account is connected.")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundStyle(.gray)
                            .font(.caption)
                    }
                })
            }
        }
        .navigationTitle("Storage")
    }
}
