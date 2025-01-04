//
//  DownloadedVideoChapter+CoreDataProperties.swift
//  Atwy
//
//  Created by Antoine Bollengier on 18.10.2023.
//
//

import Foundation
import CoreData


extension DownloadedVideoChapter {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DownloadedVideoChapter> {
        return NSFetchRequest<DownloadedVideoChapter>(entityName: "DownloadedVideoChapter")
    }

    @NSManaged public var title: String?
    @NSManaged public var thumbnail: Data?
    @NSManaged public var startTimeSeconds: Int32
    @NSManaged public var shortTimeDescription: String?
    @NSManaged public var video: DownloadedVideo?
    
    var wrapped: WrappedDownloadedVideoChapter {
        return WrappedDownloadedVideoChapter(title: title, thumbnail: thumbnail, startTimeSeconds: startTimeSeconds, shortTimeDescription: shortTimeDescription, video: video)
    }
}

extension DownloadedVideoChapter : Identifiable {

}

public struct WrappedDownloadedVideoChapter {
    public var title: String?
    public var thumbnail: Data?
    public var startTimeSeconds: Int32
    public var shortTimeDescription: String?
    public var video: DownloadedVideo?
    
    public func getEntity(context: NSManagedObjectContext) -> DownloadedVideoChapter {
        let entity = DownloadedVideoChapter(context: context)
        entity.title = title
        entity.thumbnail = thumbnail
        entity.startTimeSeconds = startTimeSeconds
        entity.shortTimeDescription = shortTimeDescription
        entity.video = video
        return entity
    }
}
