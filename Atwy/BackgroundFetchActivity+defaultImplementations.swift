//
//  BackgroundFetchActivity+defaultImplementations.swift
//  Atwy
//
//  Created by Antoine Bollengier on 15.03.2024.
//  Copyright © 2024 Antoine Bollengier. All rights reserved.
//  

import BackgroundTasks
import ActivityKit

@available(iOS 16.1, *)
extension BackgroundFetchActivity {
    func handleTask(_ task: BGTask) {
        Self.taskOperation()
        
        if
            Self.shouldRescheduleCondition(),
            let activity = LiveActivitesManager.shared.activities[Self.activityType],
            let castedActivity = activity as? Activity<ActivityAttributesType>
        {
            LiveActivitesManager.shared.updateActivity(withNewState: Self.getNewData(), activity: castedActivity)
            Self.scheduleTask()
        } else {
            Task {
                await LiveActivitesManager.shared.stopActivity(type: Self.self)
            }
        }
        task.setTaskCompleted(success: true)
    }
    
    static func setupOnManager(attributes: ActivityAttributesType, state: ActivityAttributesType.ContentState) {
        guard Self.isEnabled else { return }
        guard LiveActivitesManager.shared.getAuthorizationStatus() else { return }
        guard LiveActivitesManager.shared.activities[Self.activityType] == nil else { return }
                
        do {
            let activity: Activity<ActivityAttributesType>
            
            if #available(iOS 16.2, *) {
                activity = try Activity.request(attributes: attributes, content: .init(state: state, staleDate: nil))
            } else {
                activity = try Activity.request(attributes: attributes, contentState: state)
            }
            
            Self.setupSpecialStep(activity: activity)
                
            // Start background refresh, override the last refresh task if it wasn't already removed
            Self.scheduleTask()
                        
            LiveActivitesManager.shared.replaceActivityForType(Self.self, activity: activity)
        } catch {
            print("Error while setting up activity: \(error)")
        }
    }
    
    static func stop() {
        Task {
            await LiveActivitesManager.shared.stopActivity(type: Self.self)
        }
    }
}
