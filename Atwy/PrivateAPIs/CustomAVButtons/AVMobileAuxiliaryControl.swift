//
//  AVMobileAuxiliaryControl.swift
//  Atwy
//
//  Created by Antoine Bollengier on 29.03.2024.
//  Copyright © 2024-2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation
import UIKit
import Combine

class AVMobileAuxiliaryControl {
    let manager: CustomAVButtonsManager
    
    let control: NSObject
    let button: AnyObject?
    var priority: Int = 0 {
        didSet {
            self.setupPriorityObserver()
        }
    }
    
    private var priorityObserver: AnyCancellable? = nil
    
    init(button: AVMenuButton, priority: Int, controlName: String, manager: CustomAVButtonsManager) {
        defer {
            self.priority = priority
        }
        
        self.manager = manager
        
        // (@convention(c) (NSObject.Type, Selector, UIView, Int, NSString) -> NSObject).self
        self.control = manager.AVMobileAuxiliaryControlClass.perform(manager.AVMobileAuxiliaryControlInitWithViewSelector, with: button.button, with: priority, with: controlName as NSString).takeUnretainedValue() as! NSObject
        self.button = button
        self.setIncluded(true)
    }
    
    init(button: AVButton, priority: Int, controlName: String, manager: CustomAVButtonsManager) {
        defer {
            self.priority = priority
        }
        
        self.manager = manager
        
        // (@convention(c) (NSObject.Type, Selector, UIView, Int, NSString) -> NSObject).self
        self.control = manager.AVMobileAuxiliaryControlClass.perform(manager.AVMobileAuxiliaryControlInitWithViewSelector, with: button.button, with: priority, with: controlName as NSString).takeUnretainedValue() as! NSObject
        self.button = button
        self.priority = priority
        self.setIncluded(true)
    }
    
    init(priority: Int, controlName: String, manager: CustomAVButtonsManager) {
        defer {
            self.priority = priority
        }
        
        self.manager = manager
        
        // (@convention(c) (NSObject.Type, Selector, Int, NSString) -> NSObject).self
        self.control = manager.AVMobileAuxiliaryControlClass.perform(manager.AVMobileAuxiliaryControlInitWithoutViewSelector, with: priority, with: controlName as NSString).takeUnretainedValue() as! NSObject
        self.button = nil
        self.priority = priority
        self.setIncluded(true)
    }
    
    func setIncluded(_ included: Bool) {
        self.control.perform(NSSelectorFromString("setIncluded:"), with: included)
        if let avButton = button as? AVButton {
            avButton.setIncluded(included)
        } else if let avMenuButton = button as? AVMenuButton {
            avMenuButton.setIncluded(included)
        }
    }
    
    func setNewImageWithName(_ imageSymbolName: String) {
        if let avButton = button as? AVButton {
            avButton.setNewImageWithName(imageSymbolName)
        } else if let avMenuButton = button as? AVMenuButton {
            avMenuButton.setNewImageWithName(imageSymbolName)
        }
    }
    
    private func setupPriorityObserver() { // is needed because the main controller might change the priority unexpectedly
        let priority = self.priority
        self.priorityObserver = self.control.value(forKey: "_displayPriority").publisher.sink(receiveValue: { [weak control] _ in
            if (control?.value(forKey: "_displayPriority") as? Int ?? priority) != priority {
                control?.setValue(priority, forKey: "_displayPriority")
            }
        })
    }
}
