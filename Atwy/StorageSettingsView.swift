//
//  StorageSettingsView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 01.12.2023.
//

import SwiftUI

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
                                        print(error)
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
            }
        }
    }
}
