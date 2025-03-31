//
//  VideoCustomContextMenu.swift
//  Atwy
//
//  Created by Antoine Bollengier on 19.10.2023.
//  Copyright © 2023-2025 Antoine Bollengier. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

struct VideoCustomContextMenu<ProviderView>: ViewModifier where ProviderView: View {
    let menuItems: [UIMenuElement]
    @ViewBuilder var previewProvider: () -> ProviderView
    func body(content: Content) -> some View {
        ZStack {
            content
            UIKitContextMenuWrapper(menuItems: menuItems, previewProvider: previewProvider)
        }
    }
}

extension View {
    func contextMenuWrapper<Content>(menuItems: [UIMenuElement], @ViewBuilder previewProvider: @escaping () -> Content) -> some View where Content: View {
        modifier(VideoCustomContextMenu(menuItems: menuItems, previewProvider: previewProvider))
    }
}

struct UIKitContextMenuWrapper<Content>: UIViewRepresentable where Content: View {
    private var menuItems: [UIMenuElement]
    private var previewProvider: (() -> Content)?
    private var contextMenuDelegate: UIKitContextMenuDelegate

    
    init(menuItems: [UIMenuElement], previewProvider: ( () -> Content)? = nil) {
        self.menuItems = menuItems
        self.previewProvider = previewProvider
        var UIKitPreviewProvider: (() -> UIViewController)?
        if let previewProvider = previewProvider {
            UIKitPreviewProvider = {
                return UIHostingController(rootView: previewProvider())
            }
        }
        
        self.contextMenuDelegate = UIKitContextMenuDelegate(menuItems: menuItems, previewProvider: UIKitPreviewProvider)
    }
    
    func makeUIView(context: Context) -> UIView {
        let contentView = UIView(frame: .init(x: 0, y: 0, width: 200, height: 300))
        contentView.backgroundColor = .clear
        contentView.isUserInteractionEnabled = true
        
        let interaction = UIContextMenuInteraction(delegate: contextMenuDelegate)
        contentView.addInteraction(interaction)
        
        return contentView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
 
    class UIKitContextMenuDelegate: NSObject, UIContextMenuInteractionDelegate {
        let menuItems: [UIMenuElement]
        let previewProvider: UIContextMenuContentPreviewProvider?
        
        init(menuItems: [UIMenuElement], previewProvider: UIContextMenuContentPreviewProvider?) {
            self.menuItems = menuItems
            self.previewProvider = previewProvider
        }
        func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
            return UIContextMenuConfiguration(  identifier: UUID() as NSCopying,
                                                previewProvider: self.previewProvider,
                                                actionProvider: { _ in
                return UIMenu(title: "", children: self.menuItems)
            })
        }
    }
}
