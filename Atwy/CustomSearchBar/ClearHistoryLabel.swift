//
//  ClearHistoryLabel.swift
//  Atwy
//
//  Created by Antoine Bollengier on 16.07.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//

import UIKit

class ClearHistoryLabel: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.text = "Clear history"
        self.textColor = .secondaryLabel
        self.font = .preferredFont(forTextStyle: .caption1)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        let textRect = super.textRect(forBounds: bounds, limitedToNumberOfLines: numberOfLines)
        return textRect.inset(by: .init(top: -7, left: -7, bottom: -7, right: -7))
    }
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: .init(top: 7, left: 7, bottom: 7, right: 7)))
    }
}
