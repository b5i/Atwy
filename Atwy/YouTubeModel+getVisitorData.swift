//
//  YouTubeModel+getVisitorData.swift
//  Atwy
//
//  Created by Antoine Bollengier on 16.02.2025.
//  Copyright © 2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import YouTubeKit
import OSLog

extension YouTubeModel {
    func getVisitorData() async {
        if let visitorData = try? await SearchResponse.sendThrowingRequest(youtubeModel: YTM, data: [.query: "mrbeast"]).visitorData {
            YTM.visitorData = visitorData
        } else {
            Logger.atwyLogs.simpleLog("Couldn't get visitorData, request may fail.")
        }
    }
}
