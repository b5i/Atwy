//
//  CustomClosureTapGestureRecognizer.swift
//  Atwy
//
//  Created by Antoine Bollengier on 16.07.2024.
//  Copyright © 2024-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import UIKit
import OSLog

class CustomClosureTapGestureRecognizer: UITapGestureRecognizer {
    private let closure: () throws -> Void
    
    init(closure: @escaping () throws -> Void) {
        self.closure = closure
        super.init(target: nil, action: nil)
        self.addTarget(self, action: #selector(handleTap))
    }
    
    @objc private func handleTap() {
        do {
            try closure()
        } catch {
            Logger.atwyLogs.simpleLog("Couldn't execute CustomClosureTapGestureRecognizer's closure, error: \(error.localizedDescription).")
        }
    }
}
