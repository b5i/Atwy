//
//  View+removeCustomHeader.swift
//  Atwy
//
//  Created by Antoine Bollengier on 24.07.2024.
//  Copyright © 2024-2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//

import SwiftUI

public extension View {
    @ViewBuilder func removeCustomHeader() -> some View {
        overlay(content: {
            CustomRemoveHeaderControllerView()
                .frame(width: 0, height: 0)
        })
    }
}

public struct CustomRemoveHeaderControllerView: UIViewControllerRepresentable {
    public func makeUIViewController(context: Context) -> UIViewController {
        return ViewControllerWrapper()
    }
    
    class ViewControllerWrapper: UIViewController {
        init() {
            super.init(nibName: nil, bundle: nil)
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)

            guard let navigationController = self.navigationController, let navigationItem = navigationController.visibleViewController?.navigationItem else { return }
            
            navigationItem.perform(NSSelectorFromString("_setBottomPalette:"), with: nil)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
