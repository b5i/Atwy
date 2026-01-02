//
//  ViewRepresentable.swift
//  Atwy
//
//  Created by Antoine Bollengier on 14.10.2023.
//  Copyright © 2023-2026 Antoine Bollengier. All rights reserved.
//

import Foundation
import SwiftUI
import YouTubeKit

protocol ViewRepresentable {
    associatedtype Content: View
    @ViewBuilder func getView() -> Content
}

extension YTVideo: ViewRepresentable {
    func getView() -> some View {
        Color.clear.frame(width: 0)
    }
}

extension YTChannel: ViewRepresentable {
    func getView() -> some View {
        ChannelView(channel: self)
    }
}

extension YTPlaylist: ViewRepresentable {
    func getView() -> some View {
        PlaylistView(playlist: self)
    }
}
