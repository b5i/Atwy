//
//  CustomNavigationTitle.swift
//  Atwy
//
//  Created by Antoine Bollengier on 16.11.2023.
//

import SwiftUI

public extension View {
    @ViewBuilder func customNavigationTitleWithRightIcon<Content: View>(@ViewBuilder _ rightIcon: @escaping () -> Content) -> some View {
        overlay(content: {
            CustomNavigationTitleView(rightIcon: rightIcon)
                .frame(width: 0, height: 0)
        })
    }
}
public struct CustomNavigationTitleView<RightIcon: View>: UIViewControllerRepresentable {
    @ViewBuilder public var rightIcon: () -> RightIcon
    
    public func makeUIViewController(context: Context) -> UIViewController {
        return ViewControllerWrapper(rightContent: rightIcon)
    }
    
    class ViewControllerWrapper: UIViewController {
        var rightContent: () -> RightIcon
                
        init(rightContent: @escaping () -> RightIcon) {
            self.rightContent = rightContent
            super.init(nibName: nil, bundle: nil)
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)

            guard let navigationController = self.navigationController, let navigationItem = navigationController.visibleViewController?.navigationItem else { return }
            
            let contentView = UIHostingController(rootView: rightContent())
            contentView.view.backgroundColor = .clear
            // https://github.com/sebjvidal/UINavigationItem-LargeTitleAccessoryView-Demo
            navigationItem.perform(Selector(("_setLargeTitleAccessoryView:")), with: contentView.view)
            navigationItem.setValue(false, forKey: "_alignLargeTitleAccessoryViewToBaseline")
            navigationController.navigationBar.prefersLargeTitles = true
        }
                
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

// https://stackoverflow.com/a/49714358/16456439
extension UIResponder {
    public var parentViewController: UIViewController? {
        return next as? UIViewController ?? next?.parentViewController
    }
}
