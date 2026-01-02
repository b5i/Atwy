//
//  OSLogger+atwyLogs.swift
//  Atwy
//
//  Created by Antoine Bollengier on 14.06.2024.
//  Copyright © 2024-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import OSLog

public extension Logger {
    static let atwyLogsSubsytsem = Bundle.main.bundleIdentifier!
    
    static let atwyLogs = Logger(subsystem: atwyLogsSubsytsem, category: "all")
    func simpleLog(_ message: String) {
        self.log("\(message)")
    }
}
