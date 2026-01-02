//
//  KeyboardSearchBarView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 16.07.2024.
//  Copyright © 2024-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//

import UIKit

class KeyboardSearchBarView: UIView {
    var backgroundView: UIView!
    var magnifyingGlassImage: UIImageView!
    var clearTextButtonImage: UIImageView!
    var textField: UITextField!
    var isGettingSearchBarHeight: Bool = false
    
    let dismissAction: () -> Void
    
    private let textBinding: TextBinding
    private var textFieldObserver: AnyObject!
                
    init(textBinding: TextBinding, dismissAction: @escaping () -> Void) {
        self.textBinding = textBinding
        self.dismissAction = dismissAction
        super.init(frame: .zero)
        setupBackgroundView()
        setupMagnifyingImageView()
        setupClearButtonImageView()
        setupTextField()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        if let textFieldObserver = textFieldObserver {
            NotificationCenter.default.removeObserver(textFieldObserver)
        }
    }
    
    private func setupBackgroundView() {
        backgroundView = UIView()
        backgroundView.clipsToBounds = true
        backgroundView.layer.cornerRadius = 16
        backgroundView.layer.cornerCurve = .continuous
        backgroundView.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .gray : .white
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(backgroundView)
        
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func setupMagnifyingImageView() {
        magnifyingGlassImage = UIImageView()
        magnifyingGlassImage.tintColor = .secondaryLabel
        magnifyingGlassImage.image = UIImage(systemName: "magnifyingglass")
        magnifyingGlassImage.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .body)
        magnifyingGlassImage.translatesAutoresizingMaskIntoConstraints = false
        magnifyingGlassImage.setContentHuggingPriority(.required, for: .horizontal)
        
        backgroundView.addSubview(magnifyingGlassImage)
        
        NSLayoutConstraint.activate([
            magnifyingGlassImage.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 8),
            magnifyingGlassImage.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor)
        ])
    }
    
    private func setupClearButtonImageView() {
        clearTextButtonImage = UIImageView()
        clearTextButtonImage.tintColor = .secondaryLabel
        clearTextButtonImage.image = UIImage(systemName: "xmark.circle.fill")
        clearTextButtonImage.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .body)
        clearTextButtonImage.translatesAutoresizingMaskIntoConstraints = false
        clearTextButtonImage.setContentHuggingPriority(.required, for: .horizontal)
        
        clearTextButtonImage.layer.opacity = 0.0
        
        backgroundView.addSubview(clearTextButtonImage)
        
        NSLayoutConstraint.activate([
            clearTextButtonImage.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor)
        ])
    }
    
    private func setupTextField() {
        textField = UITextField()
        textField.delegate = self
        textField.text = textBinding.text.isEmpty ? nil : textBinding.text
        textField.placeholder = "Search"
        textField.attributedPlaceholder = NSAttributedString(string: "Search", attributes: [.foregroundColor: UIColor.secondaryLabel])
        textField.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .darkText
        textField.clearButtonMode = .always
        textField.returnKeyType = .search
        textField.spellCheckingType = .no
        textField.autocorrectionType = .no
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        textFieldObserver = NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: .main, using: { [weak self, weak textField] _ in
            guard let self = self, let textField = textField else { return }
            
            self.textBinding.text = textField.text ?? ""
        })
                
        backgroundView.addSubview(textField)
        
        NSLayoutConstraint.activate([
            clearTextButtonImage.trailingAnchor.constraint(equalTo: textField.trailingAnchor, constant: -5),
            textField.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 13),
            textField.leadingAnchor.constraint(equalTo:         magnifyingGlassImage.trailingAnchor, constant: 9),
            textField.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -8),
            textField.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -13)
        ])
    }

    func dismissKeyboard() {
        textField.resignFirstResponder()
        dismissAction()
    }
    
    @discardableResult override func becomeFirstResponder() -> Bool {
        textField.becomeFirstResponder()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        backgroundView.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .gray : .white
        textField.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .darkText
    }
}
