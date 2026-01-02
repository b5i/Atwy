//
//  View+customHeaderView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 14.03.2024.
//  Copyright © 2024-2026 Antoine Bollengier. All rights reserved.
//  

import SwiftUI

public extension View {
    @ViewBuilder func customHeaderView<Content: View>(@ViewBuilder _ headerView: @escaping () -> Content, height: CGFloat, shouldShow: (() -> Bool)? = nil) -> some View {
        overlay(content: {
            CustomNavigationHeaderView(headerView: headerView, height: height)
                .frame(width: 0, height: 0)
        })
    }
    
    @ViewBuilder func customHeaderView(_ headerViewController: UIViewController, height: CGFloat?, shouldShow: (() -> Bool)? = nil) -> some View {
        overlay(content: {
            CustomNavigationHeaderControllerView(headerViewController: headerViewController, height: height)
                .frame(width: 0, height: 0)
        })
    }
}

public struct CustomNavigationHeaderControllerView: UIViewControllerRepresentable {
    public var headerViewController: UIViewController
    
    public var height: CGFloat?
    
    public var shouldShow: (() -> Bool)?
    
    public func makeUIViewController(context: Context) -> UIViewController {
        return ViewControllerWrapper(headerViewController: headerViewController, height: height, shouldShow: shouldShow)
    }
    
    class ViewControllerWrapper: UIViewController {
        let headerViewController: UIViewController
        let shouldShow: (() -> Bool)?
        let height: CGFloat?
                
        init(headerViewController: UIViewController, height: CGFloat?, shouldShow: (() -> Bool)?) {
            self.headerViewController = headerViewController
            self.height = height
            self.shouldShow = shouldShow
            super.init(nibName: nil, bundle: nil)
        }
        
        override func viewWillAppear(_ animated: Bool) {
            guard (shouldShow?() ?? true), let navigationController = self.navigationController, let navigationItem = navigationController.visibleViewController?.navigationItem else { return }
            
            
            // a trick from https://x.com/sebjvidal/status/1748659522455937213
            
            let _UINavigationBarPalette = NSClassFromString("_UINavigationBarPalette") as! UIView.Type
            
            /* TODO: fix that
             Presenting view controller Atwy.SearchViewController from detached view controller Atwy.TopSearchBarController is not supported, and may result in incorrect safe area insets and a corrupt root presentation. Make sure Atwy.TopSearchBarController is in the view controller hierarchy before presenting from it. Will become a hard exception in a future release.

            if headerViewController.parent != navigationController {
                headerViewController.removeFromParent()
                navigationController.addChild(headerViewController)
            }
             */

            let palette = _UINavigationBarPalette.perform(NSSelectorFromString("alloc"))
                .takeUnretainedValue()
                .perform(NSSelectorFromString("initWithContentView:"), with: headerViewController.view)
                .takeUnretainedValue()
            navigationItem.perform(NSSelectorFromString("_setBottomPalette:"), with: palette)
            if let height = self.height {
                palette.setValue(height, forKey: "_preferredHeight")
            }
            //print(headerViewController.view.frame)
            super.viewWillAppear(animated)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}


public struct CustomNavigationHeaderView<HeaderView: View>: UIViewControllerRepresentable {
    @ViewBuilder public var headerView: () -> HeaderView
    let height: CGFloat
    
    public func makeUIViewController(context: Context) -> UIViewController {
        return ViewControllerWrapper(headerView: headerView, height: height)
    }
    
    class ViewControllerWrapper: UIViewController {
        let headerView: () -> HeaderView
        let height: CGFloat
                
        init(headerView: @escaping () -> HeaderView, height: CGFloat) {
            self.headerView = headerView
            self.height = height
            super.init(nibName: nil, bundle: nil)
        }
        
        override func viewWillAppear(_ animated: Bool) {
            guard let navigationController = self.navigationController, let navigationItem = navigationController.visibleViewController?.navigationItem else { return }
            
            
            // a trick from https://x.com/sebjvidal/status/1748659522455937213
            
            let _UINavigationBarPalette = NSClassFromString("_UINavigationBarPalette") as! UIView.Type
            
            let castedHeaderView = UIHostingController(rootView: self.headerView()).view
            castedHeaderView?.frame.size.height = height
            castedHeaderView?.backgroundColor = .clear
            
            let palette = _UINavigationBarPalette.perform(NSSelectorFromString("alloc"))
                .takeUnretainedValue()
                .perform(NSSelectorFromString("initWithContentView:"), with: castedHeaderView)
                .takeUnretainedValue()
            
            navigationItem.perform(NSSelectorFromString("_setBottomPalette:"), with: palette)
            
            super.viewWillAppear(animated)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
