//
//  TextBinding.swift
//  Atwy
//
//  Created by Antoine Bollengier on 16.07.2024.
//  Copyright © 2024-2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

class TextBinding {
    init(text: String, didChangeCallbacks: [(String) -> Void]) {
        self.text = text
        self.didChangeCallbacks = didChangeCallbacks
    }
    
    var text: String {
        didSet {
            didChangeCallbacks.forEach { $0(text) }
        }
    }
    
    var didChangeCallbacks: [(String) -> Void]
}
