//
//  ShareChannelView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 23.01.23.
//

import SwiftUI

struct ShareChannelView: View {
    @State var channelID: String
    var body: some View {
        ShareLink(
            item: URL(string: "Atwy://channel?\(channelID)")!,
            preview: SharePreview("Unknown channel"),
            label: {
                Image(systemName: "square.and.arrow.up")
            }
        )
    }
}
