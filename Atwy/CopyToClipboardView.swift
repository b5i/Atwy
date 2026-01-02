//
//  CopyToClipboardView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 05.12.2024.
//  Copyright © 2024-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI

struct CopyToClipboardView: View {
    let textToCopy: () -> String
    
    @State private var resetClipboardIconTimer: Timer? = nil

    @State private var copiedToClipboard: Bool = false {
        didSet {
            if self.copiedToClipboard {
                self.resetClipboardIconTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { timer in
                    self.copiedToClipboard = false
                })
            }
        }
    }
    var body: some View {
        Image(systemName: copiedToClipboard ? "doc.on.clipboard.fill" : "doc.on.clipboard")
            .resizable()
            .scaledToFit()
            .animation(.default, value: copiedToClipboard)
            .onTapGesture {
                UIPasteboard.general.string = textToCopy()
                self.copiedToClipboard = true
            }
            .frame(width: 20, height: 20)
            .contentShape(Rectangle())
            .foregroundStyle(Color.accentColor)
    }
}

#Preview {
    CopyToClipboardView(textToCopy: { "Hello, world!" })
}
