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
    var imageView: UIImageView!
    var searchLabelView: SearchMenuTitleView!
    
    private let textBinding: TextBinding
    
    private let onSubmit: () -> Void
            
    init(textBinding: TextBinding, onSubmit: @escaping () -> Void) throws {
        self.textBinding = textBinding
        self.onSubmit = onSubmit
        super.init(nibName: nil, bundle: nil)
        
        self.view.frame.size.height = 50
        
        setupBackgroundView()
        setupImageView()
        setupTextView()
        try setupTapGestureRecognizer()
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
    
    private func setupImageView() {
        imageView = UIImageView()
        imageView.tintColor = .secondaryLabel
        imageView.image = UIImage(systemName: "magnifyingglass")
        imageView.preferredSymbolConfiguration = .preferringMonochrome()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        backgroundView.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 8),
            imageView.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor)
        ])
    }
    
    private func setupTextView() {
        searchLabelView = SearchMenuTitleView(textBinding: textBinding)
        searchLabelView.text = "Search"
        searchLabelView.font = .systemFont(ofSize: 17)

        searchLabelView.textColor = .secondaryLabel
        searchLabelView.translatesAutoresizingMaskIntoConstraints = false
        
        backgroundView.addSubview(searchLabelView)
        
        NSLayoutConstraint.activate([
            searchLabelView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 8),
            searchLabelView.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor)
        ])
    }

    
    private func setupTapGestureRecognizer() throws {
        let tapGestureRecognizer = CustomClosureTapGestureRecognizer { [weak textBinding, onSubmit, weak backgroundView] in
            guard let textBinding = textBinding, let backgroundView = backgroundView else { return }
            let viewController = try SearchViewController(textBinding: textBinding, onSubmit: onSubmit)
            viewController.modalTransitionStyle = .crossDissolve
            viewController.modalPresentationStyle = .overCurrentContext
            viewController.transitioningDelegate = SearchBarAnimationDelegate.default
            
            
            //self.view.window?.rootViewController?.present(viewController, animated: true)
            backgroundView.parentViewController?.present(viewController, animated: true)
        }
        backgroundView.addGestureRecognizer(tapGestureRecognizer)
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
}
