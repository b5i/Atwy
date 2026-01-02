//
//  YouTubeChannel+showShareSheet.swift
//  Atwy
//
//  Created by Antoine Bollengier on 26.03.2024.
//  Copyright © 2024-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation
import YouTubeKit
import UIKit

public extension YouTubeChannel {
    func showShareSheet() {
        let vc = UIActivityViewController(
            activityItems: [YouTubeChannelShareSource(channel: self)],
            applicationActivities: nil
        )
        SheetsModel.shared.showSuperSheet(withViewController: vc)
    }
}
