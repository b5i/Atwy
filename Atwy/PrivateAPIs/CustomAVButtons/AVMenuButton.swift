//
//  AVMenuButton.swift
//  Atwy
//
//  Created by Antoine Bollengier on 29.03.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation
import UIKit

class AVMenuButton {
    let manager: CustomAVButtonsManager

    let button: UIButton
    let delegate: AVMenuButtonDelegate
    
    init(forImage imageSymbolName: String, menu: UIMenu, buttonDisplayName: String, buttonIdentifier: String, manager: CustomAVButtonsManager) {
        self.manager = manager
        
        if menu.title.isEmpty {
            menu.setValue(buttonDisplayName, forKey: "title")
        }
        if menu.image == nil {
            menu.setValue(UIImage(systemName: imageSymbolName), forKey: "image")
        }
    
        // (@convention(c) (NSObject.Type, Selector, NSString, NSString, Bool) -> NSObject).self
        self.button = manager.AVMenuButtonClass.perform(manager.AVMenuButtonInitSelector, with: buttonIdentifier as NSString, with: buttonDisplayName as NSString, with: true).takeUnretainedValue() as! UIButton
        self.button.frame = .init(origin: .zero, size: Self.getIdealSize())
        
        let delegate = AVMenuButtonDelegate(menu: menu, manager: manager)
        self.button.perform(manager.AVMenuButtonSetDelegateSelector, with: delegate)
        self.delegate = delegate
        
        self.setNewImageWithName(imageSymbolName)
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
        guard let manager = PrivateManager.shared.avButtonsManager else { fatalError("avButtonsManager is not initialized!") }
        self.button.perform(manager.AVMenuButtonSetIncludedSelector, with: included)
    }
    
    private static func getIdealSize() -> CGSize {
        let defaultHeight = PrivateManager.shared.avButtonsManager?.controlsView.mainInstance?.frame.height ?? 30
        return .init(width: defaultHeight, height: defaultHeight)
    }
}

class AVMenuButtonDelegate: NSObject {
    let manager: CustomAVButtonsManager

    var menu: UIMenu
    
    init(menu: UIMenu, manager: CustomAVButtonsManager) {
        self.manager = manager
        self.menu = menu
        super.init()
        if !class_conformsToProtocol(Self.self, manager.AVMenuButtonDelegateProtocol) {
            self.makeAVMenuButtonDelegateConform()
        }
    }
    
    private func makeAVMenuButtonDelegateConform() {
        for (selector, args, _) in getMethodsForProtocol(self.manager.AVMenuButtonDelegateProtocol) {
            
            if selector.description.contains("menuButtonDidHideMenu") {
                let handler: (@convention(block) (NSObject, NSObject) -> Void) = { _, _ in}

                ///https://gist.github.com/nesium/960b9401c7e615326d7941a052c82081
                let imp = imp_implementationWithBlock(unsafeBitCast(handler, to: AVMenuButtonDelegate.self))
                
                class_addMethod(AVMenuButtonDelegate.self, selector, imp, args)
            } else if selector.description.contains("menuButtonWillShowMenu") {
                let handler: (@convention(block) (NSObject, NSObject) -> Void) = { _, _ in}

                let imp = imp_implementationWithBlock(unsafeBitCast(handler, to: AVMenuButtonDelegate.self))
                
                class_addMethod(AVMenuButtonDelegate.self, selector, imp, args)
            } else if selector.description.contains("menuForMenuButton") {
                let handler: (@convention(block) (AVMenuButtonDelegate, UIButton) -> UIMenu) = { delegate, _ in
                    return delegate.menu
                }

                let imp = imp_implementationWithBlock(unsafeBitCast(handler, to: AVMenuButtonDelegate.self))
                
                class_addMethod(AVMenuButtonDelegate.self, selector, imp, args)
            }
        }
        class_addProtocol(AVMenuButtonDelegate.self, self.manager.AVMenuButtonDelegateProtocol)
    }
}
