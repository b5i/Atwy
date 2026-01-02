//
//  AVButton.swift
//  Atwy
//
//  Created by Antoine Bollengier on 29.03.2024.
//  Copyright © 2024-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation
import UIKit

class AVButton {
    let manager: CustomAVButtonsManager
    
    let button: UIButton
    
    init(forImage imageSymbolName: String, action: UIAction, accessibilityLabel: String /* we could also have an identifier for it*/, manager: CustomAVButtonsManager) {
        self.manager = manager
        
        self.button = manager.AVButtonClass.perform(manager.AVButtonInitSelector, with: accessibilityLabel as NSString, with: accessibilityLabel as NSString, with: true).takeUnretainedValue() as! UIButton
        
        self.button.frame = .init(origin: .zero, size: Self.getIdealSize())
        
        self.setNewImageWithName(imageSymbolName)
        
        self.button.addAction(action, for: .touchUpInside)
    }
    
    func setNewImageWithName(_ name: String) {
        let image = UIImage(systemName: name)!
        let imageView = UIImageView(image: image)
        imageView.tintColor = .white
        imageView.frame.size = Self.getIdealSize()
        
        self.button.perform(NSSelectorFromString("setImage:forState:"), with: image, with: UIControl.State.normal) // AVButton
        self.button.perform(NSSelectorFromString("setImageName:"), with: name) // AVButton
        self.button.setValue(imageView, forKeyPath: "_visualProvider._imageView")
        self.button.subviews.forEach({$0.removeFromSuperview()})
        self.button.addSubview(imageView)
    }
    
    func setIncluded(_ included: Bool) {
        self.button.perform(NSSelectorFromString("setIncluded:"), with: included)
    }
    
    private static func getIdealSize() -> CGSize {
        let defaultHeight = PrivateManager.shared.avButtonsManager?.controlsView.mainInstance?.frame.height ?? 30
        return .init(width: defaultHeight, height: defaultHeight)
    }
}
