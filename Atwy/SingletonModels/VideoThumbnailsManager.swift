//
//  VideoThumbnailsManager.swift
//  Atwy
//
//  Created by Antoine Bollengier on 14.10.2023.
//  Copyright © 2023-2025 Antoine Bollengier. All rights reserved.
//

import Foundation

class VideoThumbnailsManager: ObservableObject {
    public static let main = VideoThumbnailsManager()
    
    /// Image data for a videoId.
    @Published var images: [String: Data] = [:]
}
