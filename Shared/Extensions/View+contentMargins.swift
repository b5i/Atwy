//
//  ContentMarginPlacement.swift
//  Atwy
//
//  Created by Antoine Bollengier on 06.03.2025.
//  Copyright © 2025-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//

import SwiftUI

extension View {
    @ViewBuilder func contentMargins(_ edges: Edge.Set, length: CGFloat, placement: ContentMarginPlacementWrapper = .automatic) -> some View
    {
        if #available(iOS 17.0, *) {
            self
                .contentMargins(edges, length, for: {
                    switch placement {
                    case .automatic:
                        return .automatic
                    case .scrollContent:
                        return .scrollContent
                    case .scrollIndicators:
                        return .scrollIndicators
                    }
                }())
        } else {
            self
                .padding(edges, length)
        }
    }
}

enum ContentMarginPlacementWrapper {
    case automatic
    case scrollContent
    case scrollIndicators
}
