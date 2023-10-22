//
//  GoogleConnectionView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 21.10.2023.
//

import SwiftUI

struct GoogleConnectionView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var showInstructions: Bool = true
    var body: some View {
        if showInstructions {
            VStack {
                HStack(alignment: .top) {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                }
                Spacer()
                Text("Instructions")
                    .font(.title)
                    .bold()
                Text("1. Connect to your Google account.")
                    .padding(.vertical)
                    .bold()
                HStack {
                    Text("2. Click on the ")
                        .bold()
                    Image(systemName: "checkmark")
                    Text("button.")
                        .bold()
                }
                Spacer()
                Button {
                    withAnimation {
                        showInstructions = false
                    }
                } label: {
                    Text("Connect")
                        .bold()
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
        } else {
            VStack {
                #if !os(macOS)
                WebViewUI()
                    .toolbar {
                        Button {
                            NotificationCenter.default.post(name: Notification.Name("GetCookies"), object: nil)
                        } label: {
                            Image(systemName: "checkmark")
                        }
                    }
                #endif
            }
        }
    }
}
