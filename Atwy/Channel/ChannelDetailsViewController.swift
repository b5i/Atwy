//
//  ChannelDetailsViewV2.swift
//  Atwy
//
//  Created by Antoine Bollengier on 01.04.2025.
//  Copyright © 2025-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI
import YouTubeKit
import UIKit
import Combine
import InfiniteScrollViews

class ChannelDetailsViewController: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    
    init(channel: YTLittleChannelInfos) {
        self.channel = channel
        super.init(nibName: nil, bundle: nil)
                
        self.channelVideosContentController.fetchMoreResultsAction = {
            self.model.fetchContentsContinuation(for: .videos)
        }
        self.channelShortsContentController.fetchMoreResultsAction = {
            self.model.fetchContentsContinuation(for: .shorts)
        }
        self.channelDirectsContentController.fetchMoreResultsAction = {
            self.model.fetchContentsContinuation(for: .directs)
        }
        self.channelPlaylistsContentController.fetchMoreResultsAction = {
            self.model.fetchContentsContinuation(for: .playlists)
        }
        
        nowPlayingObserver = VideoPlayerModel.shared.observe(\.currentItem, changeHandler: { [weak self] model, _ in
            guard let self = self else { return }
            if model.currentItem == nil {
                for contentController in self.contentControllers {
                    UIView.transition(with: contentController.tableView, duration: 0.3, options: .transitionCrossDissolve, animations: {
                        contentController.tableView.contentInset.bottom = self.tabBarController?.tabBar.frame.height ?? 0
                    })
                }
            } else {
                for contentController in self.contentControllers {
                    UIView.transition(with: contentController.tableView, duration: 0.3, options: .transitionCrossDissolve, animations: {
                        contentController.tableView.contentInset.bottom = (self.tabBarController?.tabBar.frame.height ?? 0) + NowPlayingBarView.height
                    })
                }
            }
        })
    }
    
    private let channel: YTLittleChannelInfos
    
    private var nowPlayingObserver: Any?
    
    private var isLoadingBanner: Bool = false
    private var isLoadingAvatar: Bool = false
    
    private let model = ChannelDetailsView.Model()
    
    private var didSetInitialOffset: Bool = false
    
    private var scrollViewBottomConstraint: NSLayoutConstraint? = nil
    
    private let bannerContainer = UIView()
    private let bannerImageView: UIImageView = {
        let iv = UIImageView()
        iv.backgroundColor = .systemBackground
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    private let bannerProgressView: UIActivityIndicatorView = {
        let av = UIActivityIndicatorView(style: .medium)
        av.stopAnimating()
        return av
    }()
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let titleBackground = VariableBlurEffectView(orientation: .topToBottom)
    
    private let channelAvatarImageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 25
        return imageView
    }()
    
    private let shadowOverlayAvatarImageView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        view.backgroundColor = .clear
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0.0, height: 0.5)
        view.layer.shadowOpacity = 0.6
        view.layer.shadowRadius = 4
        view.layer.shouldRasterize = true
        view.layer.rasterizationScale = UIScreen.main.scale
        view.layer.cornerRadius = 25
        return view
    }()
    
    private let channelInfoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .systemGray
        label.sizeToFit()
        return label
    }()
    
    private let channelNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.text = "Unknown channel name"
        label.textColor = .white
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOffset = CGSize(width: 0.0, height: 0.5)
        label.layer.shadowOpacity = 0.7
        label.layer.shadowRadius = 6
        label.layer.shouldRasterize = true
        label.layer.rasterizationScale = UIScreen.main.scale
        return label
    }()
    
    private let channelNameLabelOverlay: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.text = "Unknown channel name"
        label.textColor = .white
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOffset = CGSize(width: 0.0, height: 0.5)
        label.layer.shadowOpacity = 0.7
        label.layer.shadowRadius = 6
        label.layer.shouldRasterize = true
        label.layer.rasterizationScale = UIScreen.main.scale
        return label
    }()
    
    private let contentSegmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Videos", "Shorts", "Directs", "Playlists"])
        sc.selectedSegmentIndex = 0
        return sc
    }()
    
    private let overlaySegmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Videos", "Shorts", "Directs", "Playlists"])
        sc.selectedSegmentIndex = 0
        return sc
    }()
    
    private var isChangingIndex: Bool = false

    private let navigationBarIncreaseView = UIView()
    
    private var didViewAlreadyAppeared: Bool = false
    
    private var scrollViewTopConstraint: NSLayoutConstraint?
    
    private var observers: Set<AnyCancellable> = .init()
    
    // the goal is to have a fluid transition if there's no channel banner
    // (the channel name overlay would be jumping around we need the non overlay one)
    // so we have to hide the channel name overlay until we know whether there's a banner or not
    private var isProcessingChannelInfo: Bool = false
    
    private var isUpdatingPosition = false
    private var didChangeNavigationBar = false
    private var maxContentOffset: CGFloat = 0
    private var oldScrollViewContentOffset: CGFloat = 0
    
    private var topBannerContainerConstraint: NSLayoutConstraint? = nil
    private var contentViewBottomConstraint: NSLayoutConstraint? = nil
    private var channelInfoHeightConstraint: NSLayoutConstraint? = nil
    
    private var heightRatioBannerConstraint: NSLayoutConstraint? = nil {
        didSet {
            guard oldValue != self.heightRatioBannerConstraint else { return }
            
            if let oldValue = oldValue {
                NSLayoutConstraint.deactivate([oldValue])
            }
            
            if let heightRatioBannerConstraint = self.heightRatioBannerConstraint {
                NSLayoutConstraint.activate([heightRatioBannerConstraint])
            }
        }
    }
    
    private lazy var paletteView: UIView? = {
        guard let paletteType = NSClassFromString("_UINavigationBarPalette") as? UIView.Type else { return nil }
        
        // https://x.com/SebJVidal/status/1748659522455937213
        return paletteType
            .perform(NSSelectorFromString("alloc"))
            .takeUnretainedValue()
            .perform(NSSelectorFromString("initWithContentView:"), with: navigationBarIncreaseView)
            .takeUnretainedValue() as? UIView
    }()
        
    private let channelVideosContentController = UIKitInfiniteScrollViewController()
    private let channelShortsContentController = UIKitInfiniteScrollViewController()
    private let channelDirectsContentController = UIKitInfiniteScrollViewController()
    private let channelPlaylistsContentController = UIKitInfiniteScrollViewController()
    
    private var contentControllers: [UIKitInfiniteScrollViewController] {
        return [channelVideosContentController, channelShortsContentController, channelDirectsContentController, channelPlaylistsContentController]
    }
    
    private let supportedContentCategories: [ChannelInfosResponse.RequestTypes] = [.videos, .shorts, .directs, .playlists]
    
    private var currentContentController: UIKitInfiniteScrollViewController {
        switch self.contentSegmentedControl.selectedSegmentIndex {
        case 0:
            return channelVideosContentController
        case 1:
            return channelShortsContentController
        case 2:
            return channelDirectsContentController
        case 3:
            return channelPlaylistsContentController
        default:
            return channelVideosContentController
        }
    }
    
    private func indexForContentType(_ type: ChannelInfosResponse.RequestTypes) -> Int {
        switch type {
        case .videos:
            return 0
        case .shorts:
            return 1
        case .directs:
            return 2
        case .playlists:
            return 3
        case .custom(_):
            fatalError("UNSUPPORTED CONTENT TYPE")
        }
    }
    
    private func contentController(forType type: ChannelInfosResponse.RequestTypes) -> UIKitInfiniteScrollViewController {
        switch type {
        case .videos:
            return channelVideosContentController
        case .shorts:
            return channelShortsContentController
        case .directs:
            return channelDirectsContentController
        case .playlists:
            return channelPlaylistsContentController
        case .custom(_):
            fatalError("UNSUPPORTED CONTENT TYPE")
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func handleSegmentedControlSelectionChange(sender: UISegmentedControl) {
        guard !isChangingIndex else { return }
        self.isChangingIndex = true
        if sender != self.contentSegmentedControl {
            self.contentSegmentedControl.selectedSegmentIndex = sender.selectedSegmentIndex
        }
        if sender != self.overlaySegmentedControl {
            self.overlaySegmentedControl.selectedSegmentIndex = sender.selectedSegmentIndex
        }
        
        contentControllers.forEach { $0.view.isHidden = true }
        
        currentContentController.view.isHidden = false

        contentViewBottomConstraint?.isActive = false
        contentViewBottomConstraint = contentView.bottomAnchor.constraint(equalTo: currentContentController.view.bottomAnchor, constant: 16)
        contentViewBottomConstraint?.isActive = true
        
        self.isChangingIndex = false
        UIView.performWithoutAnimation {
            self.view.setNeedsLayout()
            self.contentView.setNeedsLayout()
            self.scrollView.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        layoutViews()
        fetchChannelInfo()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateAvatarOverlayPosition()

        self.scrollViewTopConstraint = scrollView.topAnchor.constraint(equalTo: view.window?.topAnchor ?? view.topAnchor)
        self.scrollViewTopConstraint?.isActive = true
        
        self.scrollViewBottomConstraint = scrollView.bottomAnchor.constraint(equalTo: view.window?.bottomAnchor ?? view.bottomAnchor)
        self.scrollViewBottomConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            channelVideosContentController.view.bottomAnchor.constraint(equalTo: view.window?.bottomAnchor ?? view.bottomAnchor),
            channelShortsContentController.view.bottomAnchor.constraint(equalTo: view.window?.bottomAnchor ?? view.bottomAnchor),
            channelDirectsContentController.view.bottomAnchor.constraint(equalTo: view.window?.bottomAnchor ?? view.bottomAnchor),
            channelPlaylistsContentController.view.bottomAnchor.constraint(equalTo: view.window?.bottomAnchor ?? view.bottomAnchor)
        ])
        
        self.scrollView.verticalScrollIndicatorInsets.top = ((view.window?.frame.height ?? view.frame.height) - view.frame.height)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        channelNameLabelOverlay.isHidden = !self.didViewAlreadyAppeared
        channelNameLabel.isHidden = self.didViewAlreadyAppeared
        overlaySegmentedControl.isHidden = false
        navigationBarIncreaseView.isHidden = false
        titleBackground.isHidden = false
        
        setupTitleBackground()
        setupNavigationBar()
    }
        
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.didViewAlreadyAppeared = true
        
        if !self.isProcessingChannelInfo {
            channelNameLabel.isHidden = true
            channelNameLabelOverlay.isHidden = false
        }
        
        for contentController in self.contentControllers {
            contentController.tableView.contentInset.bottom = self.tabBarController?.tabBar.frame.height ?? 0
        }
    }
     
    private func setupNavigationBar() {
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.barTintColor = .clear
        navigationController?.navigationBar.addSubview(channelNameLabelOverlay)
        navigationController?.navigationBar.addSubview(overlaySegmentedControl)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        didSetInitialOffset = false
        channelNameLabel.isHidden = false
        channelNameLabelOverlay.isHidden = true
        overlaySegmentedControl.isHidden = true
        navigationBarIncreaseView.isHidden = true
        titleBackground.isHidden = true
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        channelNameLabelOverlay.removeFromSuperview()
        overlaySegmentedControl.removeFromSuperview()
        titleBackground.removeFromSuperview()
        removeBiggerNavigationBar()
    }
    
    private func setupViews() {
        bannerContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bannerContainer)
        bannerImageView.translatesAutoresizingMaskIntoConstraints = false
        bannerContainer.addSubview(bannerImageView)
        
        bannerProgressView.translatesAutoresizingMaskIntoConstraints = false
        bannerImageView.addSubview(bannerProgressView)
        
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        scrollView.delegate = self
        
        channelAvatarImageView.translatesAutoresizingMaskIntoConstraints = false
        shadowOverlayAvatarImageView.addSubview(channelAvatarImageView)
        shadowOverlayAvatarImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(shadowOverlayAvatarImageView)
        channelNameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(channelNameLabel)
        channelInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(channelInfoLabel)
        contentSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(contentSegmentedControl)
        contentSegmentedControl.addTarget(self, action: #selector(handleSegmentedControlSelectionChange(sender:)), for: .valueChanged)
        overlaySegmentedControl.addTarget(self, action: #selector(handleSegmentedControlSelectionChange(sender:)), for: .valueChanged)
        
        for contentController in self.contentControllers {
            self.addChild(contentController)
            contentController.view.translatesAutoresizingMaskIntoConstraints = false
            contentController.view.isHidden = true
            self.contentView.addSubview(contentController.view)
            contentController.didMove(toParent: self)
            contentController.tableView.showsVerticalScrollIndicator = false
        }
        
        self.channelVideosContentController.view.isHidden = false
        self.scrollView.showsVerticalScrollIndicator = false
        
        channelNameLabel.textColor = .black
        overlaySegmentedControl.isHidden = true
        contentSegmentedControl.isHidden = false
        self.view.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .black : .white
        self.scrollView.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .black : .white
        self.channelNameLabelOverlay.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        self.channelNameLabel.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.view.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .black : .white
        self.scrollView.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .black : .white
        self.channelNameLabelOverlay.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        self.channelNameLabel.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
    }
    
    private func setupTitleBackground() {
        navigationController?.navigationBar.perform(NSSelectorFromString("_setBackgroundView:"), with: titleBackground)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        return true
    }
        
    
    private func layoutViews() {
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.isScrollEnabled = true
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        self.heightRatioBannerConstraint = bannerContainer.heightAnchor.constraint(equalTo: bannerContainer.widthAnchor, multiplier: 339.0/2048.0)
        self.topBannerContainerConstraint = bannerContainer.topAnchor.constraint(equalTo: contentView.topAnchor)
        NSLayoutConstraint.activate([
            self.topBannerContainerConstraint!,
            bannerContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bannerContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bannerContainer.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            
            bannerImageView.topAnchor.constraint(equalTo: bannerContainer.topAnchor),
            bannerImageView.leadingAnchor.constraint(equalTo: bannerContainer.leadingAnchor),
            bannerImageView.trailingAnchor.constraint(equalTo: bannerContainer.trailingAnchor),
            bannerImageView.bottomAnchor.constraint(equalTo: bannerContainer.bottomAnchor),
            bannerImageView.widthAnchor.constraint(equalTo: bannerContainer.widthAnchor),
            bannerImageView.heightAnchor.constraint(equalTo: bannerContainer.heightAnchor),
            
            bannerProgressView.centerXAnchor.constraint(equalTo: bannerImageView.centerXAnchor),
            bannerProgressView.centerYAnchor.constraint(equalTo: bannerImageView.centerYAnchor)
        ])
        
        
        NSLayoutConstraint.activate([
            shadowOverlayAvatarImageView.topAnchor.constraint(equalTo: bannerContainer.bottomAnchor, constant: 30),
            shadowOverlayAvatarImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            shadowOverlayAvatarImageView.widthAnchor.constraint(equalToConstant: 50),
            shadowOverlayAvatarImageView.heightAnchor.constraint(equalToConstant: 50),
            
            channelNameLabel.centerXAnchor.constraint(equalTo: shadowOverlayAvatarImageView.centerXAnchor),
            channelNameLabel.topAnchor.constraint(equalTo: shadowOverlayAvatarImageView.bottomAnchor, constant: 16),
            
            channelInfoLabel.centerXAnchor.constraint(equalTo: channelNameLabel.centerXAnchor),
            channelInfoLabel.topAnchor.constraint(equalTo: channelNameLabel.bottomAnchor, constant: 8),
            
            contentSegmentedControl.topAnchor.constraint(equalTo: channelInfoLabel.bottomAnchor, constant: 8),
            contentSegmentedControl.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            contentSegmentedControl.widthAnchor.constraint(equalTo: contentView.widthAnchor, constant: -32),
            contentSegmentedControl.heightAnchor.constraint(equalToConstant: 32),
        ])
        
        contentViewBottomConstraint = contentView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        contentViewBottomConstraint?.isActive = true
        
        channelInfoHeightConstraint = channelInfoLabel.heightAnchor.constraint(equalToConstant: channelInfoLabel.intrinsicContentSize.height)
        channelInfoHeightConstraint?.isActive = true
        
        
        for contentController in self.contentControllers {
            contentController.scrollCallback = {
                let unusedScroll = self.scrollView.contentOffset.y + $0 - min(self.scrollView.contentOffset.y + $0, self.maxContentOffset)
                self.scrollView.contentOffset.y = min(self.scrollView.contentOffset.y + $0, self.maxContentOffset)
                return unusedScroll
            }
                        
            NSLayoutConstraint.activate([
                contentController.view.topAnchor.constraint(equalTo: contentSegmentedControl.bottomAnchor, constant: 16),
                contentController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
                contentController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8)
            ])
        }
        
        NSLayoutConstraint.activate([
            channelAvatarImageView.widthAnchor.constraint(equalTo: shadowOverlayAvatarImageView.widthAnchor),
            channelAvatarImageView.heightAnchor.constraint(equalTo: shadowOverlayAvatarImageView.heightAnchor)
        ])
        
        channelNameLabelOverlay.frame.origin.x = channelNameLabel.frame.origin.x
        channelNameLabelOverlay.frame.size = channelNameLabelOverlay.text?.size(withAttributes: [.font: channelNameLabelOverlay.font]) ?? .zero
    }
        
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateAvatarOverlayPosition()
    }
    
    private var biggerNavigationBar: Bool = false
    
    private func installBiggerNavigationBar() {
        guard !biggerNavigationBar else { return }
        biggerNavigationBar = true
        navigationBarIncreaseView.frame.size.height = 0
        navigationBarIncreaseView.frame.size.width = view.frame.width
        navigationBarIncreaseView.backgroundColor = .clear
                
        guard let navigationItem = navigationController?.visibleViewController?.navigationItem else { return }
        
        guard navigationItem.value(forKey: "_bottomPalette") == nil else { return }
        
        navigationItem.perform(NSSelectorFromString("_setBottomPalette:"), with: self.paletteView)
    }
    
    private func removeBiggerNavigationBar() {
        guard biggerNavigationBar else { return }
        
        guard let navigationItem = navigationController?.visibleViewController?.navigationItem else { return }
        if navigationItem.value(forKey: "_bottomPalette") as? UIView == self.paletteView {
            navigationItem.perform(NSSelectorFromString("_setBottomPalette:"), with: nil)
        }
        biggerNavigationBar = false
    }

    private func updateAvatarOverlayPosition() {
        guard !isUpdatingPosition else { isUpdatingPosition = false; return }
        if let navigationBar = self.navigationController?.navigationBar {
            let navigationBarTopY = navigationBar.frame.origin.y + navigationBar.frame.height
            maxContentOffset = navigationBarTopY
            self.isUpdatingPosition = true
            
            // do not let the user scroll above the banner
            if scrollView.contentOffset.y < -navigationBarTopY {
                scrollView.contentOffset.y = -navigationBarTopY
                /* rubber thing
                 if scrollView.contentOffset.y < -navigationBarTopY * 2 {
                 scrollView.contentOffset.y = -navigationBarTopY * 2
                 print("set max top offset")
                 } else {
                 if scrollView.contentOffset.y < oldScrollViewContentOffset {
                 // we scroll more to the top
                 
                 let difference = oldScrollViewContentOffset - scrollView.contentOffset.y
                 
                 let percentageTillLimit = (-scrollView.contentOffset.y - navigationBarTopY) / navigationBarTopY
                 
                 print("difference", difference, "percentageTillLimit", percentageTillLimit, "curr pos", scrollView.contentOffset.y, "old pos", oldScrollViewContentOffset, "new", oldScrollViewContentOffset - difference * (percentageTillLimit))
                 
                 scrollView.contentOffset.y = oldScrollViewContentOffset - difference * (percentageTillLimit)
                 
                 } else {
                 // we scroll to the bottom
                 
                 let difference = scrollView.contentOffset.y - oldScrollViewContentOffset
                 
                 let percentageTillLimit = (-scrollView.contentOffset.y - navigationBarTopY) / navigationBarTopY
                 
                 print("sec", "difference", difference, "percentageTillLimit", percentageTillLimit, "curr pos", scrollView.contentOffset.y, "old pos", oldScrollViewContentOffset, "new", oldScrollViewContentOffset - difference * (percentageTillLimit))
                 
                 scrollView.contentOffset.y = oldScrollViewContentOffset + difference * (percentageTillLimit)
                 }
                 }
                 */
            }
            
            // if the user scrolls on the main scrollview, we "transfer" the scroll to the content scrollview
            
            if scrollView.contentOffset.y > navigationBarTopY {
                if scrollView.contentOffset.y - navigationBarTopY >= 0.001 {
                    self.scrollView.isScrollEnabled = false
                    let amountToTransferToController = scrollView.contentOffset.y - navigationBarTopY
                    currentContentController.scrollAction = true
                    currentContentController.tableView.contentOffset.y = min(currentContentController.tableView.contentOffset.y + amountToTransferToController, currentContentController.tableView.contentSize.height - currentContentController.tableView.frame.height)
                    self.isUpdatingPosition = true
                    self.scrollView.contentOffset.y = navigationBarTopY
                    print(self.scrollView.contentOffset.y, currentContentController.tableView.contentOffset.y)
                }
            } else {
                self.scrollView.isScrollEnabled = true
            }
            
            // if the user scroll to the top with the main scrollview and that the content scrollview isn't scrolled to the top we need to transfer the scroll to it before we allow scrolling to the top with the main scrollview
            if self.oldScrollViewContentOffset > self.scrollView.contentOffset.y {
                if currentContentController.tableView.contentOffset.y > 0 {
                    let rest = max(0, currentContentController.tableView.contentOffset.y - (self.oldScrollViewContentOffset - self.scrollView.contentOffset.y)) - (currentContentController.tableView.contentOffset.y - (self.oldScrollViewContentOffset - self.scrollView.contentOffset.y))
                    currentContentController.scrollAction = true
                    currentContentController.tableView.contentOffset.y = max(0, currentContentController.tableView.contentOffset.y - (self.oldScrollViewContentOffset - self.scrollView.contentOffset.y))
                    self.isUpdatingPosition = true
                    self.scrollView.contentOffset.y = self.oldScrollViewContentOffset - rest
                }
            }
            self.isUpdatingPosition = false
            
            self.oldScrollViewContentOffset = self.scrollView.contentOffset.y
        }
        
        guard !isUpdatingPosition else { return }
        installBiggerNavigationBar()
        isUpdatingPosition = true
        defer {
            isUpdatingPosition = false
        }
        if let navigationBar = self.navigationController?.navigationBar, let channelFrameInView = channelNameLabel.superview?.convert(channelNameLabel.frame, to: navigationBar) {
            let navigationBarTopY = navigationBar.frame.origin.y - navigationBar.safeAreaInsets.top
            
            channelNameLabelOverlay.frame.origin.y = max(channelFrameInView.origin.y, (navigationBar.frame.height - navigationBarIncreaseView.frame.height - channelNameLabelOverlay.frame.height) / 2)
            
            if let contentSegmentedControlFrameOnScreen = contentSegmentedControl.superview?.convert(contentSegmentedControl.frame, to: navigationBar) {
                if didChangeNavigationBar {
                    didChangeNavigationBar = false
                }
                overlaySegmentedControl.frame.origin.y = max(contentSegmentedControlFrameOnScreen.origin.y, navigationBarTopY)
                
                let newHeight = max(0, overlaySegmentedControl.frame.size.height + 30 - overlaySegmentedControl.frame.origin.y + navigationBarTopY)
                
                if let oldHeight = paletteView?.value(forKey: "_preferredHeight") as? CGFloat, (oldHeight * 1000).rounded() != (newHeight * 1000).rounded() { // so we aren't stuck in an infinite loop because of a 0.000000001 change somewhere
                    navigationBarIncreaseView.frame.size.height = newHeight
                    paletteView?.frame.size.height = newHeight
                    paletteView?.setValue(navigationBarIncreaseView.frame.size.height, forKey: "_preferredHeight")
                    navigationController?.visibleViewController?.navigationItem.perform(NSSelectorFromString("_setBottomPaletteNeedsUpdate"))
                }
            }
            
            overlaySegmentedControl.frame.size = contentSegmentedControl.frame.size
            overlaySegmentedControl.frame.origin.x = contentSegmentedControl.frame.origin.x
            
            
            // we need to check whether the overlay control touches the navigation bar and so can react to touches, otherwise we hide it and let the classic contentsegmentedcontrol be controlled
            let overlaySegmentedControlFrameInWindow = overlaySegmentedControl.convert(overlaySegmentedControl.bounds, to: nil)
            let otherViewFrameInWindow = navigationBarIncreaseView.convert(navigationBarIncreaseView.bounds, to: nil)
            
            overlaySegmentedControl.isHidden = !overlaySegmentedControlFrameInWindow.intersects(otherViewFrameInWindow)
            contentSegmentedControl.isHidden = overlaySegmentedControlFrameInWindow.intersects(otherViewFrameInWindow)
            
            channelNameLabelOverlay.frame.size = channelNameLabelOverlay.text?.size(withAttributes: [.font: channelNameLabelOverlay.font as Any]) ?? .zero
            channelNameLabelOverlay.frame.origin.x = (channelNameLabelOverlay.superview?.frame.width ?? 0) / 2 - channelNameLabelOverlay.frame.width / 2
            channelNameLabel.frame.size = channelNameLabelOverlay.text?.size(withAttributes: [.font: channelNameLabelOverlay.font as Any]) ?? .zero
            channelNameLabel.frame.origin.x = (channelNameLabelOverlay.superview?.frame.width ?? 0) / 2 - channelNameLabelOverlay.frame.width / 2
        } else {
            channelNameLabelOverlay.frame.origin.y = channelAvatarImageView.frame.maxY
            channelNameLabelOverlay.frame.origin.x = channelNameLabel.frame.origin.x
        }
    }
    
    private func fetchChannelInfo() {
        self.isProcessingChannelInfo = true
        model.fetchInfos(channel: self.channel)
        model.$isFetchingChannelInfos
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { _ in
                if self.model.channelInfos == nil {
                    self.channelNameLabel.isHidden = false
                    self.channelNameLabelOverlay.isHidden = true
                }
                self.updateUI()
                
                for contentType in self.supportedContentCategories {
                    let categoryExists = self.model.channelInfos?.requestParams[contentType] != nil
                    let segmentIndex = self.indexForContentType(contentType)
                    let noContentCategoryFetched = self.model.channelInfos?.channelContentStore[contentType] == nil
                    self.contentSegmentedControl.setEnabled(categoryExists, forSegmentAt: segmentIndex)
                    self.overlaySegmentedControl.setEnabled(categoryExists, forSegmentAt: segmentIndex)
                    
                    if noContentCategoryFetched {
                        self.model.fetchCategoryContents(for: contentType)
                    }
                    
                    if categoryExists {
                        if self.contentSegmentedControl.selectedSegmentIndex == -1 {
                            self.contentSegmentedControl.selectedSegmentIndex = segmentIndex
                        }
                        if self.overlaySegmentedControl.selectedSegmentIndex == -1 {
                            self.overlaySegmentedControl.selectedSegmentIndex = segmentIndex
                        }
                    }
                }
            })
            .store(in: &observers)
        model.$fetchingStates
            .combineLatest(model.$continuationsFetchingStates)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { _ in
                let ytKitItemsToAtwy: ([any YTSearchResult]) -> ([YTElementWithData]) = { items in
                    var count = 0
                    return items.map { item in
                        if var video = item as? YTVideo {
                            video.channel?.thumbnails = self.model.channelInfos?.avatarThumbnails ?? []
                            video.id = count
                            count += 1
                            
                            let videoWithData = YTElementWithData(element: video, data: .init(allowChannelLinking: false))
                            return videoWithData
                        } else if var playlist = item as? YTPlaylist {
                            playlist.channel?.thumbnails = self.model.channelInfos?.avatarThumbnails ?? []
                            playlist.id = count
                            count += 1
                            
                            let playlistWithData = YTElementWithData(element: playlist, data: .init(allowChannelLinking: false))
                            return playlistWithData
                        }
                        count += 1
                        return YTElementWithData(element: item, data: .init())
                    }
                }
                
                for contentCategory in self.supportedContentCategories {
                    let contentController = self.contentController(forType: contentCategory)
                    let categoryContentFetched = self.model.channelInfos?.channelContentStore[contentCategory] != nil
                    contentController.isFetchingContent = (self.model.fetchingStates[contentCategory] ?? false || self.model.continuationsFetchingStates[contentCategory] ?? false)
                    
                    if categoryContentFetched {
                        contentController.items = ytKitItemsToAtwy(((self.model.channelInfos?.channelContentStore[contentCategory] as? (any ListableChannelContent))?.items ?? []))
                        if contentController.items.isEmpty {
                            let controllerIndex = self.indexForContentType(contentCategory)
                            self.contentSegmentedControl.setEnabled(!contentController.items.isEmpty, forSegmentAt: controllerIndex)
                            self.overlaySegmentedControl.setEnabled(!contentController.items.isEmpty, forSegmentAt: controllerIndex)
                        }
                    }
                }
            })
            .store(in: &observers)
    }
    
    private func loadAvatar() {
        if let avatarURL = model.channelInfos?.avatarThumbnails.last?.url ?? channel.thumbnails.last?.url, !self.isLoadingAvatar, self.channelAvatarImageView.image == nil {
            self.isLoadingAvatar = true
            self.loadImage(from: avatarURL) { [weak self] image in
                self?.isLoadingAvatar = false
                guard let self = self else { return }
                DispatchQueue.main.async {
                    UIView.transition(with: self.channelAvatarImageView, duration: 0.4, options: .transitionCrossDissolve, animations: { [weak self] in
                        self?.channelAvatarImageView.image = image
                    }, completion: nil)
                }
            }
        }
    }
    
    private func loadBanner() {
        if let banner = model.channelInfos?.bannerThumbnails.last {
            if self.bannerImageView.image == nil && !self.isLoadingBanner {
                // the goal is to have a fluid transition if there's no channel banner
                // (the channel name overlay would be jumping around we need the non overlay one)
                self.channelNameLabel.isHidden = true
                self.channelNameLabelOverlay.isHidden = false
                self.isLoadingBanner = true
                DispatchQueue.main.safeSync {
                    self.bannerProgressView.startAnimating()
                }
                loadImage(from: banner.url) { [weak self] image in
                    DispatchQueue.main.async {
                        self?.bannerProgressView.stopAnimating()
                        self?.isLoadingBanner = false
                        guard let self = self, let image = image else { return }
                        UIView.transition(with: self.bannerImageView, duration: 0.4, options: .transitionCrossDissolve, animations: { [weak self] in
                            self?.bannerImageView.image = image
                        })
                        self.heightRatioBannerConstraint = self.bannerContainer.heightAnchor.constraint(equalTo: self.bannerContainer.widthAnchor, multiplier: (image.size.height + 0.01) / (image.size.width + 0.01))
                        self.isProcessingChannelInfo = false
                        self.isProcessingChannelInfo = false
                    }
                }
            }
        } else if model.channelInfos != nil {
            self.heightRatioBannerConstraint = self.bannerContainer.heightAnchor.constraint(equalToConstant: 0)
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            } completion: { finished in
                if finished {
                    self.channelNameLabel.isHidden = true
                    self.channelNameLabelOverlay.isHidden = false
                    self.isProcessingChannelInfo = false
                }
            }
        }
    }
    
    private func updateInfoLabel() {
        channelNameLabel.text = model.channelInfos?.name ?? channel.name ?? "Unkown channel name"
        channelNameLabelOverlay.text = model.channelInfos?.name ?? channel.name ?? "Unkown channel name"
       
        var channelInfoText = ""
        channelInfoText += model.channelInfos?.handle ?? ""
        if model.channelInfos?.handle != nil && model.channelInfos?.subscriberCount != nil {
            channelInfoText += " • "
        }
        channelInfoText += model.channelInfos?.subscriberCount ?? ""
        if (model.channelInfos?.handle != nil || model.channelInfos?.subscriberCount != nil) || model.channelInfos?.videoCount != nil {
            channelInfoText +=  " • "
        }
        channelInfoText += model.channelInfos?.videoCount ?? ""
        if channelInfoText.isEmpty {
            channelInfoText += " "
        }
        UIView.transition(with: self.channelInfoLabel, duration: 0.4, options: .transitionCrossDissolve, animations: { [weak self] in
            self?.channelInfoLabel.text = channelInfoText
        }, completion: nil)
        
        channelInfoHeightConstraint?.constant = channelInfoLabel.intrinsicContentSize.height
    }
    
    private func updateUI() {
        if let navigationBar = self.navigationController?.navigationBar, !self.didSetInitialOffset {
            self.didSetInitialOffset = true
            let navigationBarTopY = navigationBar.frame.origin.y + navigationBar.frame.height
            self.scrollView.contentOffset.y = -navigationBarTopY // all the way to the top to show the whole image
        }
        
        loadAvatar()
        loadBanner()
        updateInfoLabel()
        updateAvatarOverlayPosition()
    }
    
    private func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, let image = UIImage(data: data) else {
                completion(nil)
                return
            }
            completion(image)
        }
        task.resume()
    }
}
