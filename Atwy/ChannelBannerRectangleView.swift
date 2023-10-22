//
//  ChannelBannerRectangleView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 23.01.23.
//

import SwiftUI

struct ChannelBannerRectangleView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State var channelBannerURL: URL?
    var body: some View {
        GeometryReader { geometry in
            VStack {
                if channelBannerURL != nil {
                    CachedAsyncImage(url: channelBannerURL, content: { image in
                        image
                            .resizable()
                            .opacity(0.8)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: geometry.size.width)
                    }, placeholder: {
                        ProgressView()
                    })
                } else {
                    Rectangle()
                        .foregroundColor(colorScheme.textColor)
                }
            }
        }
    }
}
