//
//  PopupsModel.swift
//  Atwy
//
//  Created by Antoine Bollengier on 22.10.2023.
//  Copyright © 2023-2025 Antoine Bollengier. All rights reserved.
//

import Foundation
import SwiftUI

public class PopupsModel: ObservableObject {
    public static let shared = PopupsModel()
    
    @Published public var shownPopup: (type: PopupType, data: Any?)?
    
    private var currentTimer: Timer?
    
    public init(shownPopup: (type: PopupType, data: Any?)? = nil, currentTimer: Timer? = nil) {
        self.shownPopup = shownPopup
        self.currentTimer = currentTimer
        
        NotificationCenter.default.addObserver(forName: .atwyPopup, object: nil, queue: .main, using: { notification in
            if let notifType = notification.userInfo?["PopupType"] as? String, let castedType = PopupType(rawValue: notifType) {
                self.showPopup(castedType, data: notification.userInfo?["PopupData"] as? Data)
            }
        })
    }
        
    public func showPopup(_ type: PopupType, data: Any? = nil) {
        self.currentTimer?.invalidate()
        DispatchQueue.main.async {
            withAnimation {
                self.shownPopup = (type, data)
            }
        }
        self.currentTimer = .scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: false)
    }
    
    public func hidePopup() {
        DispatchQueue.main.async {
            withAnimation {
                self.shownPopup = nil
            }
        }
    }
    
    @objc private func updateTimer() {
        self.currentTimer = nil
        self.hidePopup()
    }
    
    public enum PopupType: String, RawRepresentable {
        case playNext
        case playLater
        case addedToPlaylist
        case addedToFavorites
        case deletedDownload
        case resumedDownload
        case pausedDownload
        case cancelledDownload
    }
}
