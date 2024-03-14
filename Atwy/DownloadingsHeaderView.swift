//
//  DownloadingsHeaderView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 14.03.2024.
//  Copyright © 2024 Antoine Bollengier. All rights reserved.
//  

import SwiftUI

struct DownloadingsHeaderView: View {
    @ObservedObject private var DM = DownloadingsModel.shared
    var body: some View {
        List {
            Text("Downloading" + (DM.activeDownloadingsCount == 1 ? "" : "s"))
                .badge(DM.activeDownloadingsCount)
                .routeTo(.downloadings)
        }
        .padding(.top)
        .frame(height: DM.activeDownloadingsCount == 0 ? 0 : 70)
    }
}

#Preview {
    DownloadingsHeaderView()
}
