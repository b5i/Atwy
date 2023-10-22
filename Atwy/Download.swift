//
//  Download.swift
//  Atwy
//
//  Created by Antoine Bollengier on 21.10.2023.
//

import Foundation

struct Download {
    var title: String
    var owner: String
    var location: String
    var timeStamp: Date
    var thumbnailData: Data?

    init () {
        self.title = ""
        self.owner = ""
        self.location = ""
        self.timeStamp = Date.now
        self.thumbnailData = nil
    }

    init (title: String, owner: String, location: String, timeStamp: Date, thumbnailData: Data?) {
        self.title = title
        self.owner = owner
        self.location = location
        self.timeStamp = timeStamp
        self.thumbnailData = thumbnailData
    }
}
