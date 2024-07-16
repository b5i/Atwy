//
//  SearchBarBackgroundView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 16.07.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//

import UIKit

class SearchBarBackgroundView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.clipsToBounds = true
        self.layer.cornerRadius = 16
        self.layer.cornerCurve = .continuous
        self.backgroundColor = .tertiarySystemFill
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return self
    }
}
