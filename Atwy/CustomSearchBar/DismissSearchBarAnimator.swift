//
//  DismissSearchBarAnimator.swift
//  Atwy
//
//  Created by Antoine Bollengier on 16.07.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

/*

import UIKit
 
class DismissSearchBarAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        return 0.0
    }
    
    func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        //let fromViewController = transitionContext.viewController(forKey: .from) as! SearchViewController
        
        let toViewController = transitionContext.viewController(forKey: .to) as! TopSearchBarController
        
        toViewController.view.isHidden = false
        /*
        let blurredBackground = fromViewController.backgroundView!

        let containerView = transitionContext.containerView
        containerView.addSubview(fromViewController.view)
        //containerView.addSubview(fromViewController.searchBar)
        //containerView.addSubview(fromViewController.titleBackground)
        //containerView.addSubview(fromViewController.titleLabel)
        //containerView.addSubview(fromViewController.clearHistoryLabel)
        //containerView.addSubview(fromViewController.autocompletionScrollView)
        
        let visibleCells = fromViewController.autocompletionScrollView.visibleCells
        //visibleCells.forEach { containerView.addSubview($0) }
                
        //fromViewController.view.isHidden = true
        toViewController.view.isHidden = false
                        
        UIView.animate(
            withDuration: 4,// 0.7,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 1.75,
            options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction],
            animations: {
            toViewController.view.isHidden = false
            
            fromViewController.searchBar.dismissKeyboard()
            fromViewController.searchBar.alpha = 0
            fromViewController.titleBackground.alpha = 0
            fromViewController.titleLabel.alpha = 0
            fromViewController.clearHistoryLabel.alpha = 0
                fromViewController.keyboardBackdropView.frame.origin.y += 800
            visibleCells.forEach { $0.alpha = 0 }
        }, completion: { isCompleted in
            guard isCompleted else { return }
            fromViewController.view.removeFromSuperview()
            //fromViewController.searchBar.removeFromSuperview()
            //fromViewController.titleBackground.removeFromSuperview()
            //fromViewController.titleLabel.removeFromSuperview()
            //fromViewController.clearHistoryLabel.removeFromSuperview()
            //fromViewController.autocompletionScrollView.removeFromSuperview()
            //visibleCells.forEach { $0.removeFromSuperview() }
        })
        
        UIView.animate(
            withDuration: 8,// 0.7,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 1.75,
            options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction]
        ) {
            fromViewController.autocompletionScrollView.backgroundView?.alpha = 0.0 // alpha is good for the moment but directly modifying the intensity would be better
        } completion: { (isCompleted) in
            //fromViewController.autocompletionScrollView.backgroundView.removeFromSuperview()
            transitionContext.completeTransition(isCompleted)
        }
         */
    }
}
*/
