//
//  YTPlaylist+matchQuery.swift
//  Atwy
//
//  Created by Antoine Bollengier on 21.03.2024.
//  Copyright © 2024-2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import YouTubeKit

extension YTPlaylist {
    func matchQuery(_ query: String) -> Bool {
        query == "" || !query.lowercased().components(separatedBy: " ").filter({$0 != ""}).contains(where: {!(title?.lowercased().contains($0) ?? false || channel?.name?.lowercased().contains($0) ?? false)})
    }
}
