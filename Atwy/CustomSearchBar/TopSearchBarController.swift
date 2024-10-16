//
//  TopSearchBarController.swift
//  Atwy
//
//  Created by Antoine Bollengier on 16.07.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import UIKit

class TopSearchBarController: UIViewController {
    static var searchBarHeight: CGFloat? = nil
    
    var backgroundView: SearchBarBackgroundView!
    var magnifyingGlassImage: UIImageView!
    var clearTextButtonImage: UIImageView!
    var searchLabelView: SearchMenuTitleView!
    
    private let textBinding: TextBinding
    
    private let onSubmit: () -> Void
            
    init(textBinding: TextBinding, onSubmit: @escaping () -> Void) {
        self.textBinding = textBinding
        self.onSubmit = onSubmit
        super.init(nibName: nil, bundle: nil)
        
        self.view.frame.size.height = 50
        
        setupBackgroundView()
        setupMagnifyingImageView()
        setupClearButtonImageView()
        setupTextView()
        setupTapGestureRecognizers()
        setupSearchLabelView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupBackgroundView() {
        backgroundView = SearchBarBackgroundView()
        backgroundView.frame.size.width = self.view.frame.width - 40
        backgroundView.frame.origin.x = 20
        backgroundView.frame.size.height = 36
        
        view.addSubview(backgroundView)
    }
    
    private func setupMagnifyingImageView() {
        magnifyingGlassImage = UIImageView()
        magnifyingGlassImage.tintColor = .secondaryLabel
        magnifyingGlassImage.image = UIImage(systemName: "magnifyingglass")
        magnifyingGlassImage.preferredSymbolConfiguration = .preferringMonochrome()
        magnifyingGlassImage.translatesAutoresizingMaskIntoConstraints = false
        
        backgroundView.addSubview(magnifyingGlassImage)
        
        NSLayoutConstraint(
            item: magnifyingGlassImage!, attribute: NSLayoutConstraint.Attribute.height,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: magnifyingGlassImage, attribute: NSLayoutConstraint.Attribute.width,
            multiplier: magnifyingGlassImage.image!.size.height / magnifyingGlassImage.image!.size.width, constant: 0.0).isActive = true
        
        NSLayoutConstraint.activate([            magnifyingGlassImage.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 8),
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
                
        backgroundView.addSubview(clearTextButtonImage)
        
        NSLayoutConstraint.activate([
            clearTextButtonImage.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -8),
            clearTextButtonImage.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor)
        ])
        
        textBinding.didChangeCallbacks.append { [weak self] _ in
            self?.updateClearButtonVisibility()
        }
        
        updateClearButtonVisibility()
    }
    
    private func setupTextView() {
        searchLabelView = SearchMenuTitleView(textBinding: textBinding)
        searchLabelView.text = "Search"
        searchLabelView.font = .systemFont(ofSize: 17)

        searchLabelView.textColor = .secondaryLabel
        searchLabelView.translatesAutoresizingMaskIntoConstraints = false
        
        backgroundView.addSubview(searchLabelView)
        
        NSLayoutConstraint.activate([
            searchLabelView.leadingAnchor.constraint(equalTo: magnifyingGlassImage.trailingAnchor, constant: 8),
            searchLabelView.trailingAnchor.constraint(equalTo: clearTextButtonImage.leadingAnchor, constant: -8),
            searchLabelView.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor)
        ])
    }

    
    private func setupTapGestureRecognizers() {
        let backgroundTapGestureRecognizer = CustomClosureTapGestureRecognizer { [weak textBinding, onSubmit, weak backgroundView] in
            guard let textBinding = textBinding, let backgroundView = backgroundView else { return }
            let viewController = try SearchViewController(textBinding: textBinding, onSubmit: onSubmit)
            viewController.modalTransitionStyle = .crossDissolve
            viewController.modalPresentationStyle = .overCurrentContext
            viewController.transitioningDelegate = SearchBarAnimationDelegate.default
            
            
            //self.view.window?.rootViewController?.present(viewController, animated: true)
            backgroundView.parentViewController?.present(viewController, animated: true)
        }
        backgroundView.addGestureRecognizer(backgroundTapGestureRecognizer)
        
        let clearButtonTapGestureRecognizer = CustomClosureTapGestureRecognizer { [weak self] in
            guard let self = self else { return }
            
            self.textBinding.text = ""
            
            self.updateClearButtonVisibility()
            self.onSubmit()
        }
        clearTextButtonImage.isUserInteractionEnabled = true
        clearTextButtonImage.addGestureRecognizer(clearButtonTapGestureRecognizer)
    }
    
    private func setupSearchLabelView() {
        searchLabelView.text = textBinding.text.isEmpty ? "Search" : textBinding.text
        searchLabelView.textColor = textBinding.text.isEmpty ? .secondaryLabel : searchLabelView.traitCollection.userInterfaceStyle == .dark ? .white : .darkText
                
        textBinding.didChangeCallbacks.append { [weak searchLabelView] text in
            guard let searchLabelView = searchLabelView else { return }
            searchLabelView.text = text.isEmpty ? "Search" : text
            searchLabelView.textColor = text.isEmpty ? .secondaryLabel : searchLabelView.traitCollection.userInterfaceStyle == .dark ? .white : .darkText
        }
    }
    
    func updateClearButtonVisibility() {
        self.clearTextButtonImage.layer.opacity = self.textBinding.text.isEmpty ? 0 : (self.traitCollection.userInterfaceStyle == .dark ? 0.4 : 0.45)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateClearButtonVisibility()
    }
}
