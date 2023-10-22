//
//  PrivacyIconView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 10.02.23.
//

import SwiftUI
import YouTubeKit

struct PrivacyIconView: View {
    @State var privacy: YTPrivacy
    var body: some View {
        switch privacy {
        case .private:
            privacyIcon("lock.fill")
        case .unlisted:
            privacyIcon("link")
        case .public:
            privacyIcon("globe")
        }
    }
    
    @ViewBuilder func privacyIcon(_ privacyIconName: String) -> some View {
        Image(systemName: privacyIconName)
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
    }
}
