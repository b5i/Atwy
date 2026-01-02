//
//  View+centered.swift
//  Atwy
//
//  Created by Antoine Bollengier on 03.01.2024.
//  Copyright © 2024-2026 Antoine Bollengier. All rights reserved.
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
