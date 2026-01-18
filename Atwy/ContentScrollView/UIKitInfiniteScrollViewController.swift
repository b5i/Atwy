//
//  UIKitInfiniteScrollViewController.swift
//  Atwy
//
//  Created by Antoine Bollengier on 02.01.2026.
//  Copyright © 2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import UIKit
import YouTubeKit

class UIKitInfiniteScrollViewController: UIViewController {
    var items: [YTElementWithData] = [] {
        didSet {
            self.tableView.reloadData()
            
            DispatchQueue.main.async {
                self.tableView.layoutIfNeeded()
                self.onContentSizeChange?(self.tableView.contentSize)
            }
        }
    }
    var fetchNewResultsAtKLast: Int = 10
    var fetchMoreResultsAction: (() -> Void)?
    var refreshAction: ((@escaping () -> Void) -> Void)?
    var scrollCallback: ((CGFloat) -> CGFloat)? = nil
    var isFetchingContent: Bool = false {
        didSet {
            guard oldValue != isFetchingContent else { return }
            if isFetchingContent {
                fetchIndicator.startAnimating()
            } else {
                fetchIndicator.stopAnimating()
            }
        }
    }
    
    var onContentSizeChange: ((CGSize) -> Void)?
    private var contentSizeObservation: NSKeyValueObservation?
    
    private var tableView: UITableView!
    private let refreshControl = UIRefreshControl()
    private let fetchIndicator = UIActivityIndicatorView(style: .medium)
    
    var contentOffset: CGPoint {
        get {
            return self.tableView.contentOffset
        }
        set {
            let initialScrollAction = scrollAction
            scrollAction = true
            self.tableView.contentOffset = newValue
            scrollAction = initialScrollAction
        }
    }
    
    func changeContentInsetBottomAnimated(to newInsetBottom: CGFloat, duration: TimeInterval) {
        UIView.transition(with: self.tableView, duration: duration, options: .transitionCrossDissolve, animations: {
            self.tableView.contentInset.bottom = newInsetBottom
        })
    }
    
    // Transfer a scroll amount to the tableview while making sure we don't exceed content size
    func transferScrollAmount(_ amount: CGFloat) {
        self.contentOffset.y = min(self.contentOffset.y + amount, self.tableView.contentSize.height - self.tableView.frame.height)
    }
    
    deinit {
        contentSizeObservation?.invalidate()
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        configureHierarchy()
        configureDataSource()
        
        contentSizeObservation = tableView.observe(\.contentSize, options: .new) { [weak self] _, change in
            guard let newSize = change.newValue else { return }
            DispatchQueue.main.async {
                self?.onContentSizeChange?(newSize)
            }
        }
    }
    
    private var oldContentOffset: CGFloat = 0
    private var viewDidAlreadyScroll: Bool = false
    private var scrollAction: Bool = false
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let scrollCallback = scrollCallback, !scrollAction else { scrollAction = false; return }
        if !self.viewDidAlreadyScroll {
            self.viewDidAlreadyScroll = true
        }
        let newContentOffset = self.tableView.contentOffset.y
        scrollAction = true
        self.tableView.contentOffset.y = scrollCallback(newContentOffset)
        oldContentOffset = self.tableView.contentOffset.y
    }
    
    private func configureHierarchy() {
        tableView = UITableView(frame: view.frame, style: .plain)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.backgroundColor = .systemBackground
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        view.addSubview(tableView)
        
        tableView.estimatedRowHeight = self.view.frame.size.width * 9/16 + 105
        tableView.tableFooterView = fetchIndicator
    }
    
    private func configureDataSource() {
        tableView.register(VideoInScrollViewCell.self, forCellReuseIdentifier: VideoInScrollViewCell.reuseIdentifier)
        tableView.register(ChannelCell.self, forCellReuseIdentifier: ChannelCell.reuseIdentifier)
        tableView.register(PlaylistCell.self, forCellReuseIdentifier: PlaylistCell.reuseIdentifier)
    }
    
    var animatedUntil: Int = -1
}

extension UIKitInfiniteScrollViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let toReturn: AnimatableCell
        switch self.items[indexPath.row].element {
        case is YTVideo:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: VideoInScrollViewCell.reuseIdentifier, for: indexPath) as? VideoInScrollViewCell else {
                fatalError("Could not dequeue VideoInScrollViewCell")
            }
            cell.configure(with: self.items[indexPath.row], parentVC: self)
            cell.layoutIfNeeded()
            toReturn = cell
            
        case let channel as YTChannel:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ChannelCell.reuseIdentifier, for: indexPath) as? ChannelCell else {
                fatalError("Could not dequeue ChannelCell")
            }
            cell.configure(with: channel)
            cell.layoutIfNeeded()
            toReturn = cell
            
        case is YTPlaylist:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: PlaylistCell.reuseIdentifier, for: indexPath) as? PlaylistCell else {
                fatalError("Could not dequeue PlaylistCell")
            }
            cell.configure(with: self.items[indexPath.row], parentVC: self)
            cell.layoutIfNeeded()
            toReturn = cell
            
        default:
            fatalError("Unknown item type")
        }
        if indexPath.item > animatedUntil && !view.isHidden && !self.viewDidAlreadyScroll && self.tableView.visibleCells.reduce(0, {$0 + $1.frame.height}) < self.tableView.visibleSize.height { // TODO: fix UITableViewAlertForVisibleCellsAccessDuringUpdate
            animatedUntil += 1
            toReturn.hasAnimated = false
            print(indexPath.item, "can animate", "animatedUntil", animatedUntil)
        } else {
            toReturn.hasAnimated = true
        }
        return toReturn
    }
        
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let animatableCell = cell as? AnimatableCell else { return }
        if !animatableCell.hasAnimated {
            animatableCell.animate()  // make sure the animation takes place
        }
        // trigger fetch when user is `fetchNewResultsAtKLast` items from the end
        if indexPath.item == items.count - fetchNewResultsAtKLast {
            Task {
                fetchMoreResultsAction?()
            }
            print("fetch more")
        }
    }
        
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        switch self.items[indexPath.row].element {
        case is YTVideo:
            return self.view.frame.size.width * 9/16 + 105
        default:
            return 180
        }
    }
}

