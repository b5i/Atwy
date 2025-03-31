//
//  SearchViewController.swift
//  Atwy
//
//  Created by Antoine Bollengier on 16.07.2024.
//  Copyright © 2024-2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//

// Design inspired from https://github.com/sebjvidal/Photos-Search-UI-Demo

import UIKit
import Combine

class SearchViewController: UIViewController {
    typealias BackdropStyle = UIView.BackdropStyle
    
    private static let topSearchTitleBackgroundHeight: CGFloat = 50
    static let searchTitleLeadingPadding: CGFloat = 24
    
    let textBinding: TextBinding
    
    var searchBar: KeyboardSearchBarView!
    var clearHistoryLabel: ClearHistoryLabel!
    var autocompletionScrollView: UITableView!
    var searchHistoryIndicationLabel: SearchHistoryIndicationLabel!

    private var backgroundView: UIVisualEffectView!
    private var keyboardBackdropView: UIVisualEffectView!
    private var titleLabel: UILabel!
    private var titleBackground: VariableBlurEffectView!
            
    private var publishersStorage: Set<AnyCancellable> = .init()
        
    private let onSubmit: () -> Void
    
    private let model: SearchView.Model = .shared
    
    private var isGettingSearchBarHeight: Bool = false
    
    init(textBinding: TextBinding, onSubmit: @escaping () -> Void) throws {
        self.textBinding = textBinding
        self.onSubmit = onSubmit
        super.init(nibName: nil, bundle: nil)
        setupAutocompletionAndHistory()
        setupBackgroundView()
        keyboardBackdropView = try view.addUIKKBBackdropView()
        setupSearchBar()
        setupTitleBackground()
        setupTitleLabel()
        setupClearHistoryLabel()
        setupSearchHistoryIndicationLabel()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    private func setupBackgroundView() {
        backgroundView = UIVisualEffectView()
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        
        autocompletionScrollView.backgroundView = backgroundView
        
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
         
        
        let tapGestureRecognizer = UITapGestureRecognizer()
        tapGestureRecognizer.addTarget(self, action: #selector(tapGestureRecognized))
        
        backgroundView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    private func setupAutocompletionAndHistory() {
        autocompletionScrollView = UITableView(frame: .zero, style: .plain)
        autocompletionScrollView.separatorStyle = .none
        autocompletionScrollView.dataSource = self
        autocompletionScrollView.delegate = self
        autocompletionScrollView.register(SearchHistoryEntryView.self, forCellReuseIdentifier: SearchHistoryEntryView.reuseIdentifier)
        autocompletionScrollView.allowsSelection = false
        autocompletionScrollView.translatesAutoresizingMaskIntoConstraints = false
        autocompletionScrollView.backgroundColor = .clear
        autocompletionScrollView.contentInset.top = view.safeAreaLayoutGuide.layoutFrame.minY + Self.topSearchTitleBackgroundHeight + 20
        autocompletionScrollView.contentInset.bottom = TopSearchBarController.searchBarHeight ?? 0
                
        view.addSubview(autocompletionScrollView)
        
        NSLayoutConstraint.activate([
            autocompletionScrollView.topAnchor.constraint(equalTo: view.topAnchor),
            autocompletionScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            autocompletionScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            autocompletionScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
                
        model.$autoCompletion
            .receive(on: DispatchQueue.main) // postpone the execution after the new value has actually been applied to the autoCompletion array
            .sink { [weak self] newValue in
                guard let self = self else { return }
                self.updateIndicationLabel()
                self.autocompletionScrollView?.reloadData()
            }
            .store(in: &publishersStorage)
    }
    
    private func setupSearchBar() {
        searchBar = KeyboardSearchBarView(textBinding: textBinding, dismissAction: { [weak self] in
            guard let self = self else { return }
            self.dismiss(animated: true)
            self.onSubmit()
        })
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(searchBar)
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: keyboardBackdropView.topAnchor, constant: 18),
            searchBar.leadingAnchor.constraint(equalTo: keyboardBackdropView.leadingAnchor, constant: 15),
            searchBar.trailingAnchor.constraint(equalTo: keyboardBackdropView.trailingAnchor, constant: -15),
            searchBar.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -18)
        ])
    }
    
    private func setupTitleBackground() {
        titleBackground = VariableBlurEffectView(orientation: .topToBottom)
        titleBackground.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(titleBackground)
        
        NSLayoutConstraint.activate([
            titleBackground.topAnchor.constraint(equalTo: view.topAnchor),
            titleBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            titleBackground.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Self.topSearchTitleBackgroundHeight),
            titleBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        let tapGestureRecognizer = UITapGestureRecognizer()
        tapGestureRecognizer.addTarget(self, action: #selector(tapGestureRecognized))
        
        titleBackground.addGestureRecognizer(tapGestureRecognizer)
    }
    
    private func setupTitleLabel() {
        titleLabel = UILabel()
        titleLabel.text = "Search"
        titleLabel.isUserInteractionEnabled = false
        titleLabel.font = .systemFont(ofSize: 34, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        titleBackground.contentView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: titleBackground.safeAreaLayoutGuide.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: titleBackground.leadingAnchor, constant: Self.searchTitleLeadingPadding)
        ])
    }
    
    private func setupClearHistoryLabel() {
        clearHistoryLabel = ClearHistoryLabel()
        clearHistoryLabel.isUserInteractionEnabled = true
        clearHistoryLabel.translatesAutoresizingMaskIntoConstraints = false
        
        titleBackground.contentView.addSubview(clearHistoryLabel)
        
        NSLayoutConstraint.activate([
            clearHistoryLabel.bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            clearHistoryLabel.trailingAnchor.constraint(equalTo: titleBackground.trailingAnchor, constant: -Self.searchTitleLeadingPadding)
        ])
        
        let tapGestureRecognizer = UITapGestureRecognizer()
        tapGestureRecognizer.addTarget(self, action: #selector(clearHistory))
        
        clearHistoryLabel.addGestureRecognizer(tapGestureRecognizer)
        
        clearHistoryLabel.isHidden = !textBinding.text.isEmpty || PersistenceModel.shared.currentData.searchHistory.isEmpty
        
        textBinding.didChangeCallbacks.append { [weak clearHistoryLabel] newText in
            clearHistoryLabel?.isHidden = !newText.isEmpty || PersistenceModel.shared.currentData.searchHistory.isEmpty
        }
    }
    
    private func setupSearchHistoryIndicationLabel() {
        let currentMode: SearchHistoryIndicationLabel.Mode = PreferencesStorageModel.shared.searchHistoryEnabled ? .searchToFill : .disabled
        
        self.searchHistoryIndicationLabel = SearchHistoryIndicationLabel(mode: currentMode)
        
        self.view.addSubview(self.searchHistoryIndicationLabel)
        
        self.searchHistoryIndicationLabel.sizeToFit()
        self.searchHistoryIndicationLabel.center = self.view.convert(self.view.center, from: nil)
        
        self.searchHistoryIndicationLabel.isHidden = !self.model.autoCompletion.isEmpty
         
        PreferencesStorageModel.shared.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.updateIndicationLabel()
            }
            .store(in: &self.publishersStorage)
    }
    
    private func updateIndicationLabel() {
        if self.textBinding.text.isEmpty {
            if !PreferencesStorageModel.shared.searchHistoryEnabled && PersistenceModel.shared.currentData.searchHistory.isEmpty {
                searchHistoryIndicationLabel?.switchText(toMode: .disabled)
            } else if PersistenceModel.shared.currentData.searchHistory.isEmpty {
                searchHistoryIndicationLabel?.switchText(toMode: .searchToFill)
            }
        } else if self.model.autoCompletion.isEmpty {
            searchHistoryIndicationLabel?.switchText(toMode: .noAutoCompletionEntries)
        }
        self.searchHistoryIndicationLabel.isHidden = self.textBinding.text.isEmpty ? !PersistenceModel.shared.currentData.searchHistory.isEmpty : !self.model.autoCompletion.isEmpty
    }
    
    @objc private func tapGestureRecognized(_ sender: UITapGestureRecognizer) {
        if !self.isGettingSearchBarHeight {
            dismiss(animated: true)
        }
    }
    
    @objc private func clearHistory() {
        PersistenceModel.shared.removeSearchHistory()
        self.autocompletionScrollView.reloadData()
        self.clearHistoryLabel.isHidden = true
        self.updateIndicationLabel()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if autocompletionScrollView.cellForRow(at: .init(row: 0, section: 0)) != nil {
            autocompletionScrollView.scrollToRow(at: .init(row: 0, section: 0), at: .top, animated: false)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.autocompletionScrollView.reloadData()
        
        transitionCoordinator?.animate { [weak searchBar, weak backgroundView] _ in
            searchBar?.becomeFirstResponder()
            backgroundView?.effect = UIBlurEffect(style: .regular)
        }
        
        if TopSearchBarController.searchBarHeight == nil {
            self.isGettingSearchBarHeight = true
            self.searchBar.isGettingSearchBarHeight = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { [weak self] in
                guard let self = self else { return }
                TopSearchBarController.searchBarHeight = self.searchBar.frame.minY
                PreferencesStorageModel.shared.setNewValueForKey(.searchBarHeight, value: TopSearchBarController.searchBarHeight)
                self.isGettingSearchBarHeight = false
                self.searchBar.isGettingSearchBarHeight = false
            })
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        transitionCoordinator?.animate { [weak backgroundView, weak searchHistoryIndicationLabel] _ in
            backgroundView?.effect = nil
            searchHistoryIndicationLabel?.isHidden = true
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.transitionKeyboardBackdrop(toStyle: traitCollection.userInterfaceStyle == .dark ?  .darkMode : .lightMode)
    }
    
    private func transitionKeyboardBackdrop(toStyle style: BackdropStyle) {
        typealias InitFunction = @convention(c) (AnyObject, Selector, Int64) -> Void
        guard let method = class_getInstanceMethod(NSClassFromString("UIKBBackdropView"), NSSelectorFromString("transitionToStyle:")) else { return }
        let initFunction = unsafeBitCast(method_getImplementation(method), to: InitFunction.self)
        initFunction(keyboardBackdropView, NSSelectorFromString("transitionToStyle:"), style.rawValue)
    }
}
