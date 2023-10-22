//
//  View+hapticFeedbackOnTap.swift
//  Atwy
//
//  Created by Antoine Bollengier on 14.09.2023.
//

import Foundation
import SwiftUI

extension View {
    //https://codakuma.com/swiftui-haptics/
    func hapticFeedbackOnTap(style: UIImpactFeedbackGenerator.FeedbackStyle? = .light) -> some View {
        self.onTapGesture {
            if let style = style {
                let impact = UIImpactFeedbackGenerator(style: style)
                impact.prepare()
                impact.impactOccurred()
            }
        }
        
    }
}
