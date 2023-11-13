//
//  FavoriteVideo+CoreDataProperties.swift
//  Atwy
//
//  Created by Antoine Bollengier on 19.10.2023.
//
//

import Foundation
import CoreData

extension FavoriteVideo {

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
}

extension FavoriteVideo : Identifiable {}
