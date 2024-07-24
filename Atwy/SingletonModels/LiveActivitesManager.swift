//
//  LiveActivitesManager.swift
//  Atwy
//
//  Created by Antoine Bollengier on 14.03.2024.
//  Copyright © 2024 Antoine Bollengier. All rights reserved.
//  

import ActivityKit
import Combine
import BackgroundTasks

class LiveActivitesManager {
    static let shared = LiveActivitesManager()
    
    var activities: [ActivityType: any CastedActivity] = [:]
    var activitiesObservers: [ActivityType: AnyCancellable] = [:]
        
    func getAuthorizationStatus() -> Bool {
        if #available(iOS 16.1, *) {
            return ActivityAuthorizationInfo().areActivitiesEnabled
        } else {
            return false
        }
    }
    
    func removeAllActivities() {
        Task {
            if #available(iOS 16.1, *) {
                for activity in Activity<DownloadingsProgressActivity.ActivityAttributesType>.activities {
                    if #available(iOS 16.2, *) {
                        await activity.end(nil, dismissalPolicy: .immediate)
                    } else {
                        await activity.end(using: nil, dismissalPolicy: .immediate)
                    }
                }
            }
        }
    }
    
    @available(iOS 16.1, *)
    private func updateActivity<T: BackgroundFetchActivity>(withNewState newState: T.ActivityAttributesType, type: T.Type) {
        guard let currentActivity = self.activities[T.activityType] else { return }
        
        Task {
            guard let castedCurrentActivity = currentActivity as? Activity<T.ActivityAttributesType> else { return }
            guard let castedState = newState as? T.ActivityAttributesType.ContentState else { return }
            
            if #available(iOS 16.2, *) {
                await castedCurrentActivity.update(.init(state: castedState, staleDate: nil))
            } else {
                await castedCurrentActivity.update(using: castedState)
            }
        }
    }
    
    @available(iOS 16.1, *)
    func updateActivity<T: ActivityAttributes>(withNewState newState: T.ContentState, activity: Activity<T>) {
        Task {
            if #available(iOS 16.2, *) {
                await activity.update(.init(state: newState, staleDate: nil))
            } else {
                await activity.update(using: newState)
            }
        }
    }
    
    @available(iOS 16.1, *)
    func replaceActivityForType<T: BackgroundFetchActivity>(_ type: T.Type, activity: CastedActivity) {
        Task {
            await self.stopActivity(type: type)
            
            self.activities.updateValue(activity, forKey: T.activityType)
        }
    }
    
    @available(iOS 16.1, *)
    func stopActivity<T: BackgroundFetchActivity>(type: T.Type) async {
        if let currentActivity = self.activities[T.activityType] {
            guard let castedCurrentActivity = currentActivity as? Activity<T.ActivityAttributesType> else { return }
            
            if #available(iOS 16.2, *) {
                await castedCurrentActivity.end(.init(state: T.getNewData(), staleDate: nil), dismissalPolicy: .immediate)
            } else {
                await castedCurrentActivity.end(using: T.getNewData(), dismissalPolicy: .immediate)
            }
            
            self.activities.removeValue(forKey: T.activityType)
            self.activitiesObservers[T.activityType]?.cancel()
            self.activitiesObservers.removeValue(forKey: T.activityType)
            
            // Stop background fetching
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: T.identifier)
        }
    }
    
    enum ActivityType {
        case downloadingsProgress
    }
}

extension DownloadingsProgressAttributes.DownloadingsState {
    static var modelState: Self {
        return .init(downloadingsCount: DownloadersModel.shared.activeDownloaders.count, globalProgress: DownloadersModel.shared.globalDownloadingsProgress)
    }
}

protocol CastedActivity {}

@available(iOS 16.1, *)
extension Activity: CastedActivity {}
