//
//  Collection+conditionnalFilter.swift
//  Atwy
//
//  Created by Antoine Bollengier on 09.04.2024.
//  Copyright © 2024-2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation

extension Collection {
    func conditionnalFilter(mainCondition: Bool, _ isIncluded: (Self.Element) throws -> Bool) rethrows -> [Self.Element] {
        if mainCondition {
            return try self.filter(isIncluded)
        } else {
            return self.map(\.self)
        }
    }
}
