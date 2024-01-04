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
                VStack(alignment: .leading) {
                    Text("Instructions")
                        .font(.title)
                        .bold()
                    Text("1. Connect to your Google account.")
                        .padding(.vertical)
                        .bold()
                    Text("2. Click on the ✓ button.")
                        .bold()
                    Text("Note: if you are connected on YouTube's website but clicking on the ✓ button doesn't work, you can try to reset the browser by clicking the ↻ button and reconnect again.")
                        .font(.caption)
                        .padding(.top)
                }
                .padding()
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
                            NotificationCenter.default.post(name: .atwyResetCookies, object: nil)
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        Button {
                            NotificationCenter.default.post(name: .atwyGetCookies, object: nil)
                        } label: {
                            Image(systemName: "checkmark")
                        }
                    }
                #endif
            }
        }
    }
}
