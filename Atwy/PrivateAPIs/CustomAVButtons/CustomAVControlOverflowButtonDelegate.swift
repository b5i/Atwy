//
//  CustomAVControlOverflowButtonDelegate.swift
//  Atwy
//
//  Created by Antoine Bollengier on 29.03.2024.
//  Copyright © 2024-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation
import UIKit

class CustomAVControlOverflowButtonDelegate: NSObject {
    let manager: CustomAVButtonsManager
    
    var addedItems: [NSObject] // maybe just swizzle the method and those items on top of the others
    /// an array of UIMenu or UIAction (mixed or not) that will be added to the menu of the overflow button
    var actions: [NSObject]
    var globalDelegate: NSObject
    
    private var button: NSObject? = nil {
        didSet {
            print("set buttton for", self)
        }
    }
    init(addedItems: [NSObject], actions: [NSObject], globalDelegate: NSObject, manager: CustomAVButtonsManager) {
        self.manager = manager
        
        self.addedItems = addedItems
        self.actions = actions
        self.globalDelegate = globalDelegate
        
        super.init()
        if !class_conformsToProtocol(Self.self, manager.AVControlOverflowButtonDelegateProtocol) {
            self.makeAVControlOverflowButtonDelegateConform()
        }
    }
    
    var addedItemsButtons: [NSObject] {
        var toReturn: [NSObject] = []
        for button in self.addedItems.compactMap({$0.value(forKey: "_controlView") as? NSObject}) {
            // TODO: Add protection when accessing values
            if object_getClass(button) == self.manager.AVMenuButtonClass {
                guard let buttonDelegate = button.value(forKey: "delegate") as? NSObject else { continue }
                toReturn.append(UIDeferredMenuElement.uncached({ provider in
                    guard let rawMenu = buttonDelegate.perform(NSSelectorFromString("menuForMenuButton:"), with: button), let menu = rawMenu.takeUnretainedValue() as? UIMenu else { provider([]); return}
                    provider([menu])
                }))
            } else {
                guard let action = (button.value(forKey: "_targetActions") as? [NSObject])?.first?.value(forKey: "_actionHandler") as? UIAction else { continue }
                let newAction = UIAction(handler: {_ in})
                newAction.setValue(action.value(forKey: "_handler"), forKey: "_handler")
                newAction.title = (button.value(forKey: "_accessibilityLabelOverride") as? String) ?? ""
                newAction.image = (button as! UIButton).currentImage
                toReturn.append(newAction)
            }
        }
        toReturn.append(contentsOf: self.actions)
        
        return toReturn
    }
    
    func refreshMenu(withIdentifier identifier: String? = nil, newMenu menu: UIMenu) {
        guard let interaction = self.button?.value(forKey: "_activeMenuInteraction") as? UIContextMenuInteraction else { return }
        // took from BetterMenus
        DispatchQueue.main.async {
            var didUpdateRoot: Bool = false
            interaction.updateVisibleMenu { oldMenu in
                if let identifier = identifier {
                    if oldMenu.identifier.rawValue == identifier {
                        if let menuToReplace = menu.findChildren(withIdentifier: UIMenu.Identifier(rawValue: identifier)) {
                            return menuToReplace
                        } else {
                            print("[Atwy] Didn't find menu with identifier \(identifier) in the result of body(). Not replacing current menu.")
                        }
                    }
                    return oldMenu
                } else {
                    guard !didUpdateRoot else { return UIMenu() }
                    didUpdateRoot = true
                    return menu
                }
            }
        }
    }
    
    private func makeAVControlOverflowButtonDelegateConform() {
        for (selector, args, _) in getMethodsForProtocol(self.manager.AVControlOverflowButtonDelegateProtocol) {
            
            if selector.description.contains("overflowMenuItemsForControlOverflowButton") {
                let handler: (@convention(block) (CustomAVControlOverflowButtonDelegate, UIButton) -> [NSObject]) = { delegate, button in
                    delegate.button = button
                    let defaultItems = delegate.globalDelegate.perform(NSSelectorFromString("overflowMenuItemsForControlOverflowButton:"), with: delegate.globalDelegate.value(forKey: "_overflowControl"))
                    if defaultItems != nil {
                        var castedDefaultItems: [NSObject] = (defaultItems?.takeUnretainedValue() as? [NSObject]) ?? []
                        castedDefaultItems.append(contentsOf: delegate.addedItemsButtons)
                        return castedDefaultItems
                    } else {
                        return delegate.addedItemsButtons
                    }
                }

                let imp = imp_implementationWithBlock(unsafeBitCast(handler, to: CustomAVControlOverflowButtonDelegate.self))
                
                class_addMethod(CustomAVControlOverflowButtonDelegate.self, selector, imp, args)
            }
            
            // we need to pass the willShow and didHide info to the global delegate in order for it not to dismiss automatically, but wait for the menu to close before disappearing
            if selector.description.contains("overflowButtonWillShowContextMenu") {
                let handler: (@convention(block) (CustomAVControlOverflowButtonDelegate, UIButton) -> Void) = { delegate, button in
                    delegate.button = button
                    delegate.globalDelegate.perform(NSSelectorFromString("overflowButtonWillShowContextMenu:"), with: button)
                }

                let imp = imp_implementationWithBlock(unsafeBitCast(handler, to: CustomAVControlOverflowButtonDelegate.self))
                
                class_addMethod(CustomAVControlOverflowButtonDelegate.self, selector, imp, args)
            }
            
            if selector.description.contains("overflowButtonDidHideContextMenu") {
                let handler: (@convention(block) (CustomAVControlOverflowButtonDelegate, UIButton) -> Void) = { delegate, button in
                    delegate.button = button
                    delegate.globalDelegate.perform(NSSelectorFromString("overflowButtonDidHideContextMenu:"), with: button)
                }

                let imp = imp_implementationWithBlock(unsafeBitCast(handler, to: CustomAVControlOverflowButtonDelegate.self))
                
                class_addMethod(CustomAVControlOverflowButtonDelegate.self, selector, imp, args)
            }
        }
        class_addProtocol(CustomAVControlOverflowButtonDelegate.self, self.manager.AVControlOverflowButtonDelegateProtocol)
    }
}
