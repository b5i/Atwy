//
//  CustomAVButtonsManager.swift
//  Atwy
//
//  Created by Antoine Bollengier on 08.04.2024.
//  Copyright © 2024-2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation
import UIKit
import OSLog

class CustomAVButtonsManager {
    // AVMenuButton
    let AVMenuButtonClass: UIButton.Type
    let AVMenuButtonInitSelector: Selector = NSSelectorFromString("buttonWithAccessibilityIdentifier:accessibilityLabel:isSecondGeneration:")
    let AVMenuButtonDelegateProtocol: Protocol
    let AVMenuButtonSetDelegateSelector: Selector = NSSelectorFromString("setDelegate:")
    let AVMenuButtonSetIncludedSelector: Selector = NSSelectorFromString("setIncluded:")
    
    // AVButton
    let AVButtonClass: UIButton.Type
    let AVButtonInitSelector: Selector = NSSelectorFromString("buttonWithAccessibilityIdentifier:accessibilityLabel:isSecondGeneration:")
    
    // AVMobileAuxiliaryControl
    let AVMobileAuxiliaryControlClass: NSObject.Type
    let AVMobileAuxiliaryControlInitWithViewSelector: Selector = NSSelectorFromString("controlWithView:displayPriority:identifier:")
    let AVMobileAuxiliaryControlInitWithoutViewSelector: Selector = NSSelectorFromString("controlWithDisplayPriority:identifier:")
    
    // CustomAVControlOverflowButtonDelegate
    let AVControlOverflowButtonDelegateProtocol: Protocol
    
    // AVMobileAuxiliaryControlsView
    let AVMobileAuxiliaryControlsViewClass: NSObject.Type
    
    lazy var controlsView: AVMobileAuxiliaryControlsView = { // lazy because AVMobileAuxiliaryControlsView needs the AVButtonsManager to be initialized
        AVMobileAuxiliaryControlsView(manager: self)
    }()
        
    init?() {
        
        guard let AVMenuButtonClass = NSClassFromString("AVMenuButton") as? UIButton.Type,
              let AVMenuButtonDelegateProtocol = objc_getProtocol("AVMenuButtonDelegate"),
              let AVButtonClass = NSClassFromString("AVButton") as? UIButton.Type,
              let AVMobileAuxiliaryControlClass = NSClassFromString("AVMobileAuxiliaryControl") as? NSObject.Type,
              let AVControlOverflowButtonDelegateProtocol = objc_getProtocol("AVControlOverflowButtonDelegate"),
              let AVMobileAuxiliaryControlsViewClass = NSClassFromString("AVMobileAuxiliaryControlsView") as? NSObject.Type
        else { return nil }
        
        self.AVMenuButtonClass = AVMenuButtonClass
        self.AVMenuButtonDelegateProtocol = AVMenuButtonDelegateProtocol
        self.AVButtonClass = AVButtonClass
        self.AVMobileAuxiliaryControlClass = AVMobileAuxiliaryControlClass
        self.AVControlOverflowButtonDelegateProtocol = AVControlOverflowButtonDelegateProtocol
        self.AVMobileAuxiliaryControlsViewClass = AVMobileAuxiliaryControlsViewClass
        
        // check selectors
        if !self.validateSelectors() {
            return nil
        }
    }
    
    func inject() {
        self.controlsView.injectInMethod()
    }
    
    func removeInjection() {
        self.controlsView.removeInjection()
    }
    
    private func validateSelectors() -> Bool {
        Logger.atwyLogs.simpleLog("Testing Class Methods")
        let selectorsAndClasses: [(NSObject.Type, [Selector])] = [
            (self.AVMenuButtonClass, [self.AVMenuButtonInitSelector]),
            (self.AVButtonClass, [self.AVButtonInitSelector]),
            (self.AVMobileAuxiliaryControlClass, [self.AVMobileAuxiliaryControlInitWithViewSelector, self.AVMobileAuxiliaryControlInitWithoutViewSelector])
        ]
        
        for (classType, selectors) in selectorsAndClasses {
            Logger.atwyLogs.simpleLog("Testing class with name \(String(describing: classType))")
            for selector in selectors {
                if classType.responds(to: selector) {
                    Logger.atwyLogs.simpleLog("\(String(describing: selector)) on \(String(describing: classType)) passed respond test ✅")
                } else {
                    Logger.atwyLogs.simpleLog("\(String(describing: selector)) on \(String(describing: classType)) did not pass respond test ❌")
                    return false
                }
            }
        }
        
        // TODO: test instance methods
        return true
    }
}
