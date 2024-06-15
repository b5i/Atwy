//
//  OSLogger+atwyLogs.swift
//  Atwy
//
//  Created by Antoine Bollengier on 14.06.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import OSLog

public extension Logger {
    static let atwyLogs = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "all")
    
    func simpleLog(_ message: String) {
        self.debug("\(message)")
    }
}
