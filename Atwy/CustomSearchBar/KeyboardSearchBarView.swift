//
//  KeyboardSearchBarView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 16.07.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//

import UIKit

class KeyboardSearchBarView: UIView {
    var backgroundView: UIView!
    var imageView: UIImageView!
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
        setupImageView()
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
    
    private func setupImageView() {
        imageView = UIImageView()
        imageView.tintColor = .secondaryLabel
        imageView.image = UIImage(systemName: "magnifyingglass")
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .body)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        
        backgroundView.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 8),
            imageView.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor)
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
            textField.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 13),
            textField.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 9),
            textField.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -13),
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
