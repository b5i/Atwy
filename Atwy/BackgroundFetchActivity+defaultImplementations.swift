//
//  BackgroundFetchActivity+defaultImplementations.swift
//  Atwy
//
//  Created by Antoine Bollengier on 15.03.2024.
//  Copyright © 2024 Antoine Bollengier. All rights reserved.
//  

import BackgroundTasks
import ActivityKit
import OSLog

@available(iOS 16.1, *)
extension AtwyLiveActivity {
    func setupOnManager(attributes: ActivityAttributesType, state: ActivityAttributesType.ContentState) {
        guard Self.isEnabled else { return }
        guard LiveActivitesManager.shared.getAuthorizationStatus() else { return }
                
        do {
            let activity = try LiveActivitesManager.shared.addActivity(self, attributes: attributes, state: state)
            self.setupSpecialStep(activity: activity)
            
            // Start background refresh, override the last refresh task if it wasn't already removed
            DownloaderBackgroundProgressRefreshActivity.scheduleTask()
        } catch {
            Logger.atwyLogs.simpleLog("Error while setting up activity: \(error)")
        }
    }
    
    func stop() {
        Task {
            await LiveActivitesManager.shared.stopActivity(bgActivity: self)
        }
    }
}
