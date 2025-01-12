//
//  Array<Equatable>+unique.swift
//  Atwy
//
//  Created by Antoine Bollengier on 12.01.2025.
//  Copyright © 2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

extension Array {
    func unique(_ comparator: (Element, Element) -> Bool) -> [Element] {
        var uniqueArray: [Element] = []
        
        uniqueArray.reserveCapacity(count)
        
        for element in self {
            if !uniqueArray.contains(where: { comparator($0, element) }) {
                uniqueArray.append(element)
            }
        }
        
        return uniqueArray
    }

    func unique() -> [Element] where Element: Hashable & Equatable {
        return Array(Set(self))
    }    
}
