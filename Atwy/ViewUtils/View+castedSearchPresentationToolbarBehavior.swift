//
//  View+castedSearchPresentationToolbarBehavior.swift
//  Atwy
//
//  Created by Antoine Bollengier on 05.12.2024.
//  Copyright © 2024-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI

extension View {
    @ViewBuilder func castedSearchPresentationToolbarBehavior(avoidHidingContent: Bool) -> some View {
        if #available(iOS 17.1, *) {
            self.searchPresentationToolbarBehavior(avoidHidingContent ? .avoidHidingContent : .automatic)
        } else {
            self
        }
    }
}
