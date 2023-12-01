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
}

extension DownloadedVideoChapter : Identifiable {

}
