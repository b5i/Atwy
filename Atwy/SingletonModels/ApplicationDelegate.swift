//
//  ApplicationDelegate.swift
//  Atwy
//
//  Created by Antoine Bollengier on 09.08.2024.
//  Copyright © 2024-2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import UIKit

class ApplicationDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        if #available(iOS 16.1, *) {
            DownloaderBackgroundProgressRefreshActivity.registerTask()
        }
        return true
    }
}
