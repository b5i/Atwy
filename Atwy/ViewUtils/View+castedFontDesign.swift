//
//  View+castedFontDesign.swift
//  Atwy
//
//  Created by Antoine Bollengier on 05.12.2024.
//  Copyright © 2024-2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI

extension View {
    @ViewBuilder func castedFontDesign(_ design: Font.Design) -> some View {
        if #available(iOS 16.1, *) {
            self.fontDesign(.monospaced)
        } else {
            self
        }
    }
}
