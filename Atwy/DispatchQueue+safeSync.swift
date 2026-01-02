//
//  DispatchQueue+safeSync.swift
//  Atwy
//
//  Created by Antoine Bollengier on 22.10.2024.
//  Copyright © 2024-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//

import Foundation

extension DispatchQueue {
    func safeSync(execute block: () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            self.sync {
                block()
            }
        }
    }
}
