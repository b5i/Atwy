//
//  DownloadedVideo+CoreDataProperties.swift
//  Atwy
//
//  Created by Antoine Bollengier on 18.10.2023.
//
//

import Foundation
import CoreData


extension DownloadedVideo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DownloadedVideo> {
        return NSFetchRequest<DownloadedVideo>(entityName: "DownloadedVideo")
    }

    @NSManaged public var videoId: String
    @NSManaged public var videoDescription: String?
    @NSManaged public var title: String?
    @NSManaged public var timestamp: Date
    @NSManaged public var timeLength: String?
    @NSManaged public var timePosted: String?
    @NSManaged public var thumbnail: Data?
    @NSManaged public var storageLocation: URL
    @NSManaged public var channel: DownloadedChannel?
    @NSManaged public var chapters: NSSet?

    public override func awakeFromInsert() {
        timestamp = Date()
    }
    
    public var chaptersArray: [DownloadedVideoChapter] {
        let set = chapters as? Set<DownloadedVideoChapter> ?? []
        
        return set.sorted {
            $0.startTimeSeconds < $1.startTimeSeconds
        }
    }
}

// MARK: Generated accessors for chapters
extension DownloadedVideo {

    @objc(addChaptersObject:)
    @NSManaged public func addToChapters(_ value: DownloadedVideoChapter)

    @objc(removeChaptersObject:)
    @NSManaged public func removeFromChapters(_ value: DownloadedVideoChapter)

    @objc(addChapters:)
    @NSManaged public func addToChapters(_ values: NSSet)

    @objc(removeChapters:)
    @NSManaged public func removeFromChapters(_ values: NSSet)

}

extension DownloadedVideo : Identifiable {

}
