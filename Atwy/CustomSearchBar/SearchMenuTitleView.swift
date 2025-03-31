//
//  SearchMenuTitleView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 16.07.2024.
//  Copyright © 2024-2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import UIKit

class SearchMenuTitleView: UILabel {
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let textBinding: TextBinding
    
    init(textBinding: TextBinding) {
        self.textBinding = textBinding
        super.init(frame: .zero)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.textColor = textBinding.text.isEmpty ? .secondaryLabel : self.traitCollection.userInterfaceStyle == .dark ? .white : .darkText
    }
}
