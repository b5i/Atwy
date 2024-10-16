//
//  SearchHistoryDisabledLabel.swift
//  Atwy
//
//  Created by Antoine Bollengier on 18.07.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//

import UIKit

class SearchHistoryIndicationLabel: UILabel {
    init(mode: Mode) {
        super.init(frame: .zero)
        
        self.switchText(toMode: mode)
        self.textColor = .secondaryLabel
    }
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func switchText(toMode mode: Mode) {
        self.text = mode.rawValue
        self.sizeToFit()
        self.frame.origin.x = ((self.superview?.frame.width ?? 0) - self.frame.width) / 2
    }
    
    enum Mode: String {
        case disabled = "Search History disabled"
        case searchToFill = "Search things to fill your Search History"
        case noAutoCompletionEntries = "No Auto Completion entries"
    }
}
