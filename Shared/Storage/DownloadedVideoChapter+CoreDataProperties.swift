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
    
    struct NonEntityDownloadedVideoChapter {
        var title: String?
        var thumbnail: Data?
        var startTimeSeconds: Int32
        var shortTimeDescription: String?
        var video: DownloadedVideo?
        
        func getEntity(context: NSManagedObjectContext) -> DownloadedVideoChapter {
            let entity = DownloadedVideoChapter(context: context)
            entity.title = title
            entity.thumbnail = thumbnail
            entity.startTimeSeconds = startTimeSeconds
            entity.shortTimeDescription = shortTimeDescription
            entity.video = video
            return entity
        }
    }
}

extension DownloadedVideoChapter : Identifiable {

}
