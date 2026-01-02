//
//  PrivacyIconView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 10.02.23.
//  Copyright © 2023-2026 Antoine Bollengier. All rights reserved.
//

import SwiftUI
import YouTubeKit

struct PrivacyIconView: View {
    let privacy: YTPrivacy
    var body: some View {
        Image(systemName: Self.getIconNameForPrivacyType(self.privacy))
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
    }
    
    static func getIconNameForPrivacyType(_ type: YTPrivacy) -> String {
        switch type {
        case .private:
            return "lock.fill"
        case .public:
            return "globe"
        case .unlisted:
            return "link"
        }
    }
}
