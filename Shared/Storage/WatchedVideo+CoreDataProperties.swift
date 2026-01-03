//
//  WatchedVideo+CoreDataProperties.swift
//  Atwy
//
//  Created by Antoine Bollengier on 03.01.2026.
//  Copyright © 2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//  
//

public import Foundation
public import CoreData


public typealias WatchedVideoCoreDataPropertiesSet = NSSet

extension WatchedVideo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WatchedVideo> {
        return NSFetchRequest<WatchedVideo>(entityName: "WatchedVideo")
    }

    @NSManaged public var timestamp: Date
    @NSManaged public var videoId: String
    @NSManaged public var watchedUntil: Double
    @NSManaged public var watchedPercentage: Double

    public override func awakeFromInsert() {
        timestamp = Date()
    }
}

extension WatchedVideo : Identifiable {

}
