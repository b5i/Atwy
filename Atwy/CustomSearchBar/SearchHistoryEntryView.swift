//
//  SearchHistoryEntryView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 16.07.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//

import UIKit

class SearchHistoryEntryView: UITableViewCell {
    static let reuseIdentifier: String = "SearchHistoryEntryView"
    
    var removeAction: (() -> Void)?

    private let entryLabel = UILabel()
    
    private var text: String? = nil
    private var clickAction: () -> Void = {}
    private var tapGestureRecognizerLabel: UIGestureRecognizer? = nil
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.backgroundColor = .clear
        self.selectionStyle = .none

        
        self.entryLabel.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(entryLabel)
        
        NSLayoutConstraint.activate([
            entryLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 8 + SearchViewController.searchTitleLeadingPadding),
            entryLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -13)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("SearchHistoryEntryView coder init is not implemented.")
    }
    
    func setupView(forText text: String, clickAction: @escaping () -> Void, removeAction: (() -> Void)?) {
        self.text = text
        self.clickAction = clickAction
        self.removeAction = removeAction
        setupEntryLabel()
        setupTapGestureRecognizers()
    }
    
    private func setupEntryLabel() {
        self.entryLabel.frame.size.width = 200
        self.entryLabel.frame.size.height = 30
        self.entryLabel.text = text
        self.entryLabel.textAlignment = .left
        self.entryLabel.lineBreakMode = .byTruncatingTail
        self.entryLabel.numberOfLines = 1
        self.entryLabel.font = .boldSystemFont(ofSize: 24)
        self.entryLabel.textColor = traitCollection.userInterfaceStyle == .dark ? .white : .black
    }
    
    private func setupTapGestureRecognizers() {
        guard tapGestureRecognizerLabel == nil else { return }
        tapGestureRecognizerLabel = UITapGestureRecognizer()
        tapGestureRecognizerLabel!.addTarget(self, action: #selector(tapGestureRecognized))
        self.addGestureRecognizer(tapGestureRecognizerLabel!)
    }
    
    @objc private func tapGestureRecognized(_ sender: UITapGestureRecognizer) {
        clickAction()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        self.entryLabel.textColor = traitCollection.userInterfaceStyle == .dark ? .white : .black
    }
}
