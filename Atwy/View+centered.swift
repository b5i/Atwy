//
//  View+centered.swift
//  Atwy
//
//  Created by Antoine Bollengier on 03.01.2024.
//

import SwiftUI

extension View {
    @ViewBuilder func centered() -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                self
                Spacer()
            }
            Spacer()
        }
    }
}
