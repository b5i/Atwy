//
//  NotificationName+AtwyNotifications.swift
//  Atwy
//
//  Created by Antoine Bollengier on 30.11.2023.
//  Copyright © 2023-2025 Antoine Bollengier. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let atwyCoreDataChanged = Notification.Name("CoreDataChanged")
    
    static let atwyCookiesSetUp = Notification.Name("CookiesSetUp")
    
    static let atwyDownloadingsChanged = Notification.Name("DownloadingsChanged")
    
    static let atwyNoDownloadingsLeft = Notification.Name("NoDownloadingsLeft")
    
    static let atwyGetCookies = Notification.Name("GetCookies")
    
    static let atwyResetCookies = Notification.Name("ResetCookies")
    
    static let atwyStopPlayer = Notification.Name("StopPlayer")
    
    static let atwyAVPlayerEnded = Notification.Name("AVPlayerEnded")
    
    static let atwyPopup = Notification.Name("Popup")
    
    static let atwyDismissPlayerSheet = Notification.Name("DismissPlayerSheet")
        
    static func atwyDownloadingChanged(for videoId: String) -> Notification.Name { return .init("DownloadingChanged\(videoId)") }
}
