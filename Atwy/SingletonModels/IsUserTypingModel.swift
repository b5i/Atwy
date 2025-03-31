//
//  IsUserTypingModel.swift
//  Atwy
//
//  Created by Antoine Bollengier on 22.01.23.
//  Copyright © 2023-2025 Antoine Bollengier. All rights reserved.
//

import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif
class IsUserTypingModel: ObservableObject {

    static let shared = IsUserTypingModel()

    @Published var userTyping: Bool = false
    @Published var isMainSearchTextEmpty: Bool = true

    init() {
        #if !os(macOS)
        NotificationCenter.default.addObserver(self, selector: #selector(userWillType), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(userWillStopType), name: UIResponder.keyboardWillHideNotification, object: nil)
        #endif
    }

    @objc func userWillType() {
        withAnimation {
            DispatchQueue.main.async {
                self.userTyping = true
            }
        }
    }

    @objc func userWillStopType() {
        withAnimation {
             DispatchQueue.main.async {
                 self.userTyping = false
            }
        }
    }
}

