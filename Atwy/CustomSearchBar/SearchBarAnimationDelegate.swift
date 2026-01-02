//
//  SearchBarAnimationDelegate.swift
//  Atwy
//
//  Created by Antoine Bollengier on 16.07.2024.
//  Copyright © 2024-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import UIKit

class SearchBarAnimationDelegate: NSObject, UIViewControllerTransitioningDelegate {
    static let `default` = SearchBarAnimationDelegate()
    
    private let presentAnimator = PresentSearchBarAnimator()
    //let dismissAnimator = DismissSearchBarAnimator()

    func animationController(forDismissed dismissed: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        //dismissAnimator
        nil
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        presentAnimator
    }
}
