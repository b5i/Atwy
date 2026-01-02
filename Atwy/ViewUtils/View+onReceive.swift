//
//  View+onReceive.swift
//  Atwy
//
//  Created by Antoine Bollengier on 09.04.2024.
//  Copyright © 2024-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI

struct OnNotificationReceiveViewModifier: ViewModifier {
    let notificationName: Notification.Name
    var notificationCenter: NotificationCenter = .default
    var queue: OperationQueue? = nil
    
    let handler: (Notification) -> ()
    
    @State private var observer: NSObjectProtocol? = nil
    func body(content: Content) -> some View {
        content
            .onAppear {
                self.observer = self.notificationCenter.addObserver(forName: self.notificationName, object: nil, queue: self.queue, using: self.handler)
            }
            .onDisappear {
                if let observer = self.observer {
                    self.notificationCenter.removeObserver(observer)
                    self.observer = nil
                }
            }
    }
}

extension View {
    func onReceive(
        of notificationName: Notification.Name,
        notificationCenter: NotificationCenter = .default,
        queue: OperationQueue? = .main,
        handler: @escaping (Notification) -> ()
    ) -> some View {
        self
            .modifier(OnNotificationReceiveViewModifier(notificationName: notificationName, notificationCenter: notificationCenter, queue: queue, handler: handler))
    }
}
