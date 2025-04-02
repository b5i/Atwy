//
//  VariableBlurView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 08.07.2024.
//  Copyright © 2024-2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import UIKit
import SwiftUI
import CoreImage.CIFilterBuiltins

class VariableBlurEffectView: UIVisualEffectView {
    let orientation: Orientation
    let radius: CGFloat
    
    private var observer: AnyObject? = nil
    
    private static let imageForOrientation: [Orientation: CGImage?] = [
        .bottomToTop: createAlphaGradientImage(size: .init(width: 100, height: 100), orientation: .bottomToTop)?.cgImage,
        .topToBottom: createAlphaGradientImage(size: .init(width: 100, height: 100), orientation: .topToBottom)?.cgImage
    ]
    
    enum Orientation {
        /// more blur at the bottom
        case bottomToTop
        
        /// more blur at the top
        case topToBottom
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.updateBlur()
    }
    
    init(orientation: Orientation, radius: CGFloat = 20) {
        self.orientation = orientation
        self.radius = radius
        super.init(effect: UIBlurEffect(style: .regular))
        if !self.updateBlur() {
            self.effect = .some(UIBlurEffect(style: .regular))
        }
        
        self.observer = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main, using: { [weak self] _ in
            guard let self = self else { return }
            if !self.updateBlur() {
                self.effect = .some(UIBlurEffect(style: .regular))
            }
        })
    }
    
    deinit {
        if let observer = self.observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    @discardableResult
    private func updateBlur() -> Bool {
        guard PrivateManager.shared.isVariableBlurAvailable && PreferencesStorageModel.shared.variableBlurEnabled else { return false }
        
        // Adapted from https://github.com/jtrivedi/VariableBlurView

        let variableBlur = (NSClassFromString("CAFilter") as! NSObject.Type).perform(NSSelectorFromString("filterWithType:"), with: "variableBlur").takeUnretainedValue() as! NSObject

        guard let cgMaskImage = Self.imageForOrientation[orientation] else { return false }
        
        variableBlur.setValue(radius, forKey: "inputRadius")
        variableBlur.setValue(cgMaskImage, forKey: "inputMaskImage")
        variableBlur.setValue(true, forKey: "inputNormalizeEdges")
        
        // Get rid of the visual effect view's dimming/tint view, so we don't see a hard line.
        
        guard self.subviews.count > 1 else { return false }
        let tintOverlayView = subviews[1]
        tintOverlayView.alpha = 0

        // We use a `UIVisualEffectView` here purely to get access to its `CABackdropLayer`,
        // which is able to apply various, real-time CAFilters onto the views underneath.
        let backdropLayer = self.subviews.first?.layer

        // Replace the standard filters (i.e. `gaussianBlur`, `colorSaturate`, etc.) with only the variableBlur.
        backdropLayer?.filters = [variableBlur]
        
        return true
    }
    
    private static func createAlphaGradientImage(size: CGSize, orientation: Orientation) -> UIImage? {
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors: [CGColor]
        if orientation == .bottomToTop {
            colors = [
                UIColor.black.withAlphaComponent(0.0).cgColor,
                UIColor.black.withAlphaComponent(1.0).cgColor
            ]
        } else {
            colors = [
                UIColor.black.withAlphaComponent(1.0).cgColor,
                UIColor.black.withAlphaComponent(0.0).cgColor
            ]
        }
        let locations: [CGFloat] = [0.0, 1.0]

        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations) else {
            return nil
        }

        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }

        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: 0),
            end: CGPoint(x: 0, y: size.height),
            options: []
        )

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }
}

struct VariableBlurView: UIViewRepresentable {
    let orientation: VariableBlurEffectView.Orientation
    var radius: CGFloat = 20

    func makeUIView(context: Context) -> VariableBlurEffectView {
        VariableBlurEffectView(orientation: orientation, radius: radius)
    }

    func updateUIView(_ uiView: VariableBlurEffectView, context: Context) {}
}
