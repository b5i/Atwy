//
//  PrivateManager.swift
//  Atwy
//
//  Created by Antoine Bollengier on 08.04.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation

class PrivateManager {
    static let shared = PrivateManager()
    
    let avButtonsManager: CustomAVButtonsManager?
    
    let isVariableBlurAvailable: Bool
    
    init() {
        self.avButtonsManager = CustomAVButtonsManager()
        
        if let CAFilter = NSClassFromString("CAFilter") as? NSObject.Type,
           CAFilter.responds(to: NSSelectorFromString("filterWithType:"))
        {
            self.isVariableBlurAvailable = true
        } else {
            self.isVariableBlurAvailable = false
        }
    }
}
