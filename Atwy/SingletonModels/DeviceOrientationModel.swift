//
//  DeviceOrientationModel.swift
//  Atwy
//
//  Created by Antoine Bollengier on 19.07.2025.
//  Copyright © 2025-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation
import UIKit
import Combine

class DeviceOrientationModel: ObservableObject {
    static let shared = DeviceOrientationModel()
    
    @Published private(set) var orientation: UIDeviceOrientation
    
    private var observer: Any?
    var store: Set<AnyCancellable> = .init()
    private init() {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        self.orientation = UIDevice.current.orientation
        self.observer = NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main, using: { [weak self] _ in
            self?.orientation = UIDevice.current.orientation
        })
    }
    
    deinit {
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.removeObserver(observer)
    }
}
