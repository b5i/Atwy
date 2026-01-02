//
//  DownloadedVideo+matchesQuery.swift
//  Atwy
//
//  Created by Antoine Bollengier on 10.11.2023.
//  Copyright © 2023-2026 Antoine Bollengier. All rights reserved.
//

import Foundation

public extension DownloadedVideo {
    /// Method that indicates whether a video matches a certain query (takes in account the title and channel's name).
    func matchesQuery(_ query: String) -> Bool {
        return query == "" || !query.lowercased().components(separatedBy: " ").filter({$0 != ""}).contains(where: {!(title?.lowercased().contains($0) ?? false || channel?.name?.lowercased().contains($0) ?? false)})
    }
}
