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
    
    init() {
        self.avButtonsManager = CustomAVButtonsManager()
    }
}
