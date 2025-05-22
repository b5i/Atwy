//
//  SearchSectionHeaderView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 19.05.2025.
//  Copyright © 2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import UIKit

class SearchSectionHeaderView: UITableViewHeaderFooterView {
    static let reuseIdentifier: String = "SearchSectionHeaderView"
    
    static let headerSize: CGFloat = 30
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier ?? Self.reuseIdentifier)
        backgroundConfiguration = .clear()
    }
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
