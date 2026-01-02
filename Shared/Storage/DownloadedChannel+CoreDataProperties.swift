//
//  DownloadedChannel+CoreDataProperties.swift
//  Atwy
//
//  Created by Antoine Bollengier on 18.10.2023.
//  Copyright © 2023-2026 Antoine Bollengier. All rights reserved.
//

import Foundation
import CoreData


extension DownloadedChannel {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DownloadedChannel> {
        return NSFetchRequest<DownloadedChannel>(entityName: "DownloadedChannel")
    }

    @NSManaged public var channelId: String
    @NSManaged public var name: String?
    @NSManaged public var thumbnail: Data?
    @NSManaged public var videos: NSSet?
    @NSManaged public var favorites: NSSet?

    public var videosArray: [DownloadedVideo] {
        let set = videos as? Set<DownloadedVideo> ?? []
        
        return set.sorted {
            $0.timestamp < $1.timestamp
        }
    }
    
    public var favoritesArray: [FavoriteVideo] {
        let set = favorites as? Set<FavoriteVideo> ?? []
        
        return set.sorted {
            $0.timestamp < $1.timestamp
        }
    }
    
    public var wrapped: WrappedDownloadedChannel {
        return WrappedDownloadedChannel(
            channelId: self.channelId,
            name: self.name,
            thumbnail: self.thumbnail
        )
    }
}

// MARK: Generated accessors for videos
extension DownloadedChannel {

    @objc(addVideosObject:)
    @NSManaged public func addToVideos(_ value: DownloadedVideo)

    @objc(removeVideosObject:)
    @NSManaged public func removeFromVideos(_ value: DownloadedVideo)

    @objc(addVideos:)
    @NSManaged public func addToVideos(_ values: NSSet)

    @objc(removeVideos:)
    @NSManaged public func removeFromVideos(_ values: NSSet)

}

// MARK: Generated accessors for favorites
extension DownloadedChannel {

    @objc(addFavoritesObject:)
    @NSManaged public func addToFavorites(_ value: FavoriteVideo)

    @objc(removeFavoritesObject:)
    @NSManaged public func removeFromFavorites(_ value: FavoriteVideo)

    @objc(addFavorites:)
    @NSManaged public func addToFavorites(_ values: NSSet)

    @objc(removeFavorites:)
    @NSManaged public func removeFromFavorites(_ values: NSSet)

}

extension DownloadedChannel : Identifiable {

}

public struct WrappedDownloadedChannel {
    public var channelId: String
    public var name: String?
    public var thumbnail: Data?
}
