//
//  TemporalAlertsViews.swift
//  Atwy
//
//  Created by Antoine Bollengier on 05.02.23.
//

import SwiftUI

struct AlertView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State var image: String
    @State var text: String
    @State var imageData: Data?
    @State private var displayIcon: Bool = false
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .foregroundColor(colorScheme.backgroundColor)
                .opacity(0.8)
            HStack {
                ZStack {
                    // Disabled for the moment
//                    if let imageData = imageData {
//                        #if os(macOS)
//                        Image(nsImage: NSImage(data: imageData)!)
//                            .resizable()
//                            .scaledToFit()
//                            .frame(width: 34, height: 34)
//                        #else
//                        Image(uiImage: UIImage(data: imageData)!)
//                            .resizable()
//                            .scaledToFit()
//                            .frame(width: 34, height: 34)
//                        #endif
//                    }
                    Image(systemName: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 34, height: 34)
                        .animation(.easeIn, value: imageData != nil ? 0.3 : 0.0)
                        .foregroundColor(colorScheme.textColor)
                }
                Text(text)
                    .foregroundColor(colorScheme.textColor)
            }
            .padding()
            .foregroundColor(colorScheme.textColor)
        }
        .frame(width: 200, height: 54)
        .onAppear {
            withAnimation {
                self.displayIcon = true
            }
        }
    }
}

struct PlayNextAlertView: View {
    @State var imageData: Data?
    var body: some View {
        AlertView(image: "text.line.first.and.arrowtriangle.forward", text: "Next", imageData: imageData)
    }
}

struct PlayLaterAlertView: View {
    @State var imageData: Data?
    var body: some View {
        AlertView(image: "text.line.last.and.arrowtriangle.forward", text: "Later", imageData: imageData)
    }
}

struct AddedToPlaylistAlertView: View {
    @State var imageData: Data?
    var body: some View {
        AlertView(image: "plus.circle", text: "Added", imageData: imageData)
    }
}

struct AddedFavoritesAlertView: View {
    @State var imageData: Data?
    var body: some View {
        AlertView(image: "star", text: "Added to favorites", imageData: imageData)
    }
}

struct DeletedDownloadAlertView: View {
    @State var imageData: Data?
    var body: some View {
        AlertView(image: "trash", text: "Deleted", imageData: imageData)
    }
}

struct ResumedDownloadAlertView: View {
    @State var imageData: Data?
    var body: some View {
        AlertView(image: "play", text: "Resumed", imageData: imageData)
    }
}

struct PausedDownloadAlertView: View {
    @State var imageData: Data?
    var body: some View {
        AlertView(image: "pause", text: "Paused", imageData: imageData)
    }
}

struct CancelledDownloadAlertView: View {
    @State var imageData: Data?
    var body: some View {
        AlertView(image: "multiply.circle", text: "Cancelled", imageData: imageData)
    }
}
