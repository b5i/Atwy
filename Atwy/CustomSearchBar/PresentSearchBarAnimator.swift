//
//  PresentSearchBarAnimator.swift
//  Atwy
//
//  Created by Antoine Bollengier on 16.07.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import UIKit

class PresentSearchBarAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        return (TopSearchBarController.searchBarHeight == nil) ? 0.0 : 0.7
    }
    
    func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        let fromViewController = transitionContext.viewController(forKey: .from) as! TopSearchBarController
        
        let toViewController = transitionContext.viewController(forKey: .to) as! SearchViewController
        
        toViewController.view.layoutIfNeeded() // Calculate the final position and frame of the elements in the toViewController, we will only need to get the keyboard height from the PreferencesStorageModel to ajust their y origin.
        
        let initialViewImage = fromViewController.imageView!
        let finalViewImage = toViewController.searchBar.imageView!
        
        let initialViewText = fromViewController.searchLabelView!
        let finalViewText = toViewController.searchBar.textField!
        
        let initialViewBackground = fromViewController.backgroundView!
        let finalViewBackground = toViewController.searchBar.backgroundView!
        
    
                
        let containerView = transitionContext.containerView
        containerView.addSubview(toViewController.view)

        
        let imageTransitionView = UIImageView()
        imageTransitionView.clipsToBounds = true
        imageTransitionView.tintColor = initialViewImage.tintColor
        imageTransitionView.image = initialViewImage.image
        imageTransitionView.preferredSymbolConfiguration = initialViewImage.preferredSymbolConfiguration
        imageTransitionView.frame = containerView.convert(initialViewImage.frame, from: initialViewImage.superview)
        
        containerView.addSubview(imageTransitionView)
                
        
        let textTransitionView = UILabel()
        textTransitionView.clipsToBounds = true
        textTransitionView.contentMode = initialViewText.contentMode
        textTransitionView.text = initialViewText.text
        textTransitionView.textColor = initialViewText.textColor
        textTransitionView.font = initialViewText.font
        textTransitionView.layer.cornerRadius = initialViewText.layer.cornerRadius
        textTransitionView.frame = containerView.convert(initialViewText.frame, from: initialViewText.superview)
        
        containerView.addSubview(textTransitionView)
        
        let backgroundTransitionView = UIView()
        backgroundTransitionView.clipsToBounds = initialViewBackground.clipsToBounds
        backgroundTransitionView.layer.cornerRadius = initialViewBackground.layer.cornerRadius
        backgroundTransitionView.layer.cornerCurve = initialViewBackground.layer.cornerCurve
        backgroundTransitionView.backgroundColor = initialViewBackground.backgroundColor
        backgroundTransitionView.frame = containerView.convert(initialViewBackground.frame, from: initialViewBackground.superview)
        
        containerView.addSubview(backgroundTransitionView)
        containerView.addSubview(imageTransitionView)
        containerView.addSubview(textTransitionView)

                
        fromViewController.view.isHidden = true
        toViewController.searchBar.isHidden = true
        toViewController.searchHistoryIndicationLabel.isHidden = true
                        
        UIView.animate(
            withDuration: (TopSearchBarController.searchBarHeight == nil) ? 0.0 : 0.7,// 0.7,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 1.75,
            options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction]
        ) {
            imageTransitionView.frame = containerView.convert(finalViewImage.frame, from: finalViewImage.superview)
            imageTransitionView.frame.origin = .init(x: 23, y: (TopSearchBarController.searchBarHeight ?? 0) + 15)
            imageTransitionView.tintColor = finalViewImage.tintColor
            
            textTransitionView.frame = containerView.convert(finalViewText.frame, from: finalViewText.superview)
            textTransitionView.frame.origin = .init(x: 37.33 + 15, y: (TopSearchBarController.searchBarHeight ?? 0) + 13)
            textTransitionView.font = finalViewText.font
            textTransitionView.textColor = (finalViewText.text?.isEmpty ?? true) ? .secondaryLabel : finalViewText.traitCollection.userInterfaceStyle == .dark ? .white : .darkText
            textTransitionView.layer.cornerRadius = 0
            
            backgroundTransitionView.frame = containerView.convert(finalViewBackground.frame, from: finalViewBackground.superview)
            backgroundTransitionView.frame.origin = .init(x: 15, y: (TopSearchBarController.searchBarHeight ?? 0))
            backgroundTransitionView.layer.cornerRadius = finalViewBackground.layer.cornerRadius
            backgroundTransitionView.layer.cornerCurve = finalViewBackground.layer.cornerCurve
            backgroundTransitionView.backgroundColor = finalViewBackground.backgroundColor

        } completion: { (isCompleted) in
            toViewController.searchBar.isHidden = false
            fromViewController.view.isHidden = false // TODO: find a way to animate that as well
            imageTransitionView.removeFromSuperview()
            textTransitionView.removeFromSuperview()
            backgroundTransitionView.removeFromSuperview()
            transitionContext.completeTransition(isCompleted) // we don't set it as completed when displaying the autocompletion entries because it would be too long
        }
        
        guard (toViewController.autocompletionScrollView.visibleCells.first as? SearchHistoryEntryView)?.removeAction != nil else { return }
        
        toViewController.autocompletionScrollView.visibleCells.forEach { $0.alpha = 0 }
        
        let visibleCellsCount = toViewController.autocompletionScrollView.visibleCells.count
        let animationDuration = 0.2
        
        // TODO: make this work
        UIView.animateKeyframes(withDuration: Double(visibleCellsCount) * animationDuration, delay: 0.6, options: [.allowUserInteraction, .calculationModeLinear], animations: {
            for (offset, autocompletionEntry) in toViewController.autocompletionScrollView.visibleCells.enumerated() {
                UIView.addKeyframe(withRelativeStartTime: animationDuration * Double(offset), relativeDuration: animationDuration) {
                    autocompletionEntry.alpha = 1
                }
            }
        })
    }
}
