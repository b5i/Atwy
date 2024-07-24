//
//  CancelDownloadContextMenuView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 09.04.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation
import SwiftUI

struct CancelDownloadContextMenuView: View {
    @ObservedObject var downloader: HLSDownloader
    var body: some View {
        Button(role: .destructive) {
            self.downloader.cancelDownload()
        } label: {
            HStack {
                Text("Cancel download")
                Image(systemName: "multiply")
            }
        }
    }
}
