//
//  DownloadedDescriptionPart+CoreDataProperties.swift
//  Atwy
//
//  Created by Antoine Bollengier on 18.10.2023.
//
//

import Foundation
import CoreData


extension DownloadedDescriptionPart {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DownloadedDescriptionPart> {
        return NSFetchRequest<DownloadedDescriptionPart>(entityName: "DownloadedDescriptionPart")
    }
    
    @NSManaged public var text: String
    @NSManaged public var role: String?
    @NSManaged public var index: Int64
    @NSManaged public var data: Data?
    @NSManaged public var video: DownloadedVideo?
}

extension DownloadedDescriptionPart : Identifiable {

}
