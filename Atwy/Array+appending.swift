//
//  Array+appending.swift
//  Atwy
//
//  Created by Antoine Bollengier on 24.07.2024.
//  Copyright © 2024-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//

import Foundation

extension Array {
    func appending(_ newElement: Element) -> Self {
        var newArray = self
        newArray.append(newElement)
        return newArray
    }
    
    func appending(contentsOf newElements: Self) -> Self {
        var newArray = self
        newArray.append(contentsOf: newElements)
        return newArray
    }
}
