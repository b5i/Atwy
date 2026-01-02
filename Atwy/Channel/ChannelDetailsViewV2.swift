//
//  ChannelDetailsViewV2.swift
//  Atwy
//
//  Created by Antoine Bollengier on 02.01.2026.
//  Copyright © 2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI
import YouTubeKit

struct ChannelDetailsViewV2: UIViewControllerRepresentable {
    let channel: YTLittleChannelInfos
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
    
    func makeUIViewController(context: Context) -> some UIViewController {
        return ChannelDetailsViewController(channel: channel)
    }
}
