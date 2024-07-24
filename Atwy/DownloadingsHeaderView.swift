//
//  DownloadingsHeaderView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 14.03.2024.
//  Copyright © 2024 Antoine Bollengier. All rights reserved.
//  

import SwiftUI

struct DownloadingsHeaderView: View {
    @ObservedObject private var DM = DownloadersModel.shared
    var body: some View {
        let activeDownloadingsCount = DM.activeDownloaders.count
        List {
            Text("Downloading" + (activeDownloadingsCount == 1 ? "" : "s"))
                .badge(activeDownloadingsCount)
                .routeTo(.downloadings)
        }
        .padding(.top)
        .frame(height: activeDownloadingsCount == 0 ? 0 : 70)
    }
}

#Preview {
    DownloadingsHeaderView()
}
