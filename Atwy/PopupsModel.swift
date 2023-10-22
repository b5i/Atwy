//
//  PopupsModel.swift
//  Atwy
//
//  Created by Antoine Bollengier on 22.10.2023.
//

import Foundation
import SwiftUI

public class PopupsModel: ObservableObject {
    public static let shared = PopupsModel()
    
    @Published public var shownPopup: (type: PopupType, data: Any?)?
    
    private var currentTimer: Timer?
        
    public func showPopup(_ type: PopupType, data: Any? = nil) {
        self.currentTimer?.invalidate()
        withAnimation {
            self.shownPopup = (type, data)
        }
        self.currentTimer = .scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: false)
    }
    
    public func hidePopup() {
        withAnimation {
            self.shownPopup = nil
        }
    }
    
    @objc private func updateTimer() {
        self.currentTimer = nil
        self.hidePopup()
    }
    
    public enum PopupType {
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
