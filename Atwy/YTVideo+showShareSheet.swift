//
//  YTVideo+showShareSheet.swift
//  Atwy
//
//  Created by Antoine Bollengier on 25.03.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation
import YouTubeKit
import UIKit

public extension YTVideo {
    func showShareSheet(thumbnailData: Data? = nil) {
        let vc = UIActivityViewController(
            activityItems: [YTVideoShareSource(video: self, thumbnailData: thumbnailData)],
            applicationActivities: nil
        )
        SheetsModel.shared.showSuperSheet(withViewController: vc)
    }
}

