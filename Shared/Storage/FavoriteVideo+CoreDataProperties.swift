//
//  FavoriteVideo+CoreDataProperties.swift
//  Atwy
//
//  Created by Antoine Bollengier on 19.10.2023.
//  Copyright © 2023-2026 Antoine Bollengier. All rights reserved.
//

import Foundation
import CoreData

extension FavoriteVideo {
    static let sortSetting: ReferenceWritableKeyPath<PreferencesStorageModel, PreferencesStorageModel.SortingModes> = \.favoritesSortingMode
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<FavoriteVideo> {
        return NSFetchRequest<FavoriteVideo>(entityName: "FavoriteVideo")
    }

    @NSManaged public var videoId: String
    @NSManaged public var timeLength: String?
    /// Note: isn't used for the moment
    @NSManaged public var timePosted: String?
    @NSManaged public var timestamp: Date
    @NSManaged public var thumbnailData: Data?
    @NSManaged public var title: String?
    @NSManaged public var channel: DownloadedChannel?

    public override func awakeFromInsert() {
        timestamp = Date()
    }
    
    public var wrapped: WrappedFavoriteVideo {
        return WrappedFavoriteVideo(
            videoId: self.videoId,
            timeLength: self.timeLength,
            timePosted: self.timePosted,
            timestamp: self.timestamp,
            thumbnailData: self.thumbnailData,
            title: self.title
        )
    }
}

extension FavoriteVideo : Identifiable {}

public struct WrappedFavoriteVideo {
    public var videoId: String
    public var timeLength: String?
    /// Note: isn't used for the moment
    public var timePosted: String?
    public var timestamp: Date
    public var thumbnailData: Data?
    public var title: String?
}
