//
//  PrivateManager.swift
//  Atwy
//
//  Created by Antoine Bollengier on 08.04.2024.
//  Copyright © 2024-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation
import UIKit

class PrivateManager {
    static let shared = PrivateManager()
    
    let avButtonsManager: CustomAVButtonsManager?
    
    let isVariableBlurAvailable: Bool
    
    var isCustomSearchMenuAvailable: Bool // available until it's not
    
    init() {
        self.avButtonsManager = CustomAVButtonsManager()
        
        if let CAFilter = NSClassFromString("CAFilter") as? NSObject.Type,
           CAFilter.responds(to: NSSelectorFromString("filterWithType:"))
        {
            self.isVariableBlurAvailable = true
        } else {
            self.isVariableBlurAvailable = false
        }
        
        if let backdropClass = (NSClassFromString("UIKBBackdropView") as? NSObject.Type),
            let keyboardBackdropView = (backdropClass.perform(NSSelectorFromString("alloc")).takeUnretainedValue() as? UIVisualEffectView),
            keyboardBackdropView.responds(to: NSSelectorFromString("initWithFrame:style:")) {
            self.isCustomSearchMenuAvailable = true
        } else {
            self.isCustomSearchMenuAvailable = false;
        }
    }
}
