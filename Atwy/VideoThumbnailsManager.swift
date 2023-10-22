//
//  VideoThumbnailsManager.swift
//  Atwy
//
//  Created by Antoine Bollengier on 14.10.2023.
//

import Foundation

class VideoThumbnailsManager: ObservableObject {
    public static let main = VideoThumbnailsManager()
    
    /// Image data for a videoId.
    @Published var images: [String: Data] = [:]
}
