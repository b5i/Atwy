//
//  UIView+addUIKKBBackdropView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 16.07.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//

// Explanation from https://sebvidal.com/blog/reverse-engineering-photos-search-ui

import UIKit

extension UIView {
    enum BackdropStyle: Int64 {
        case lightMode = 3901
        case darkMode = 2030
        case black = 2039
    }
    
    func addUIKKBBackdropView() throws -> UIVisualEffectView {
        guard let backdropClass = (NSClassFromString("UIKBBackdropView") as? NSObject.Type) else { throw "UIKBBackdropView class does not exist." }
        
        guard let keyboardBackdropView = (backdropClass.perform(NSSelectorFromString("alloc")).takeUnretainedValue() as? UIVisualEffectView) else { throw "Could not get the UIKBBackdropView as a UIVisualEffectView." }
        
        typealias InitFunction = @convention(c) (AnyObject, Selector, CGRect, Int64) -> UIVisualEffectView?
        guard keyboardBackdropView.responds(to: NSSelectorFromString("initWithFrame:style:")) else { throw "UIKBBackdropView does not react to init selector initWithFrame:style:" }
        guard let method = class_getInstanceMethod(backdropClass, NSSelectorFromString("initWithFrame:style:")) else { throw "Could not get instanceMethod for initWithFrame:style:" }
        let initFunction = unsafeBitCast(method_getImplementation(method), to: InitFunction.self)
        
        _ = initFunction(keyboardBackdropView, NSSelectorFromString("initWithFrame:style:"), .zero, traitCollection.userInterfaceStyle == .dark ? BackdropStyle.darkMode.rawValue : BackdropStyle.lightMode.rawValue)
        
        keyboardBackdropView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(keyboardBackdropView)
        NSLayoutConstraint.activate([
            keyboardBackdropView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            keyboardBackdropView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            keyboardBackdropView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        
        return keyboardBackdropView
    }
}
