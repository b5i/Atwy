//
//  BackgroundFetchOperation+defaultImplementations.swift
//  Atwy
//
//  Created by Antoine Bollengier on 15.03.2024.
//  Copyright © 2024 Antoine Bollengier. All rights reserved.
//  

import Foundation
import BackgroundTasks
import OSLog

@available(iOS 16.1, *)
extension BackgroundFetchOperation {
    static var isScheduled: Bool {
        var result: Bool = false
        let semaphore = DispatchSemaphore(value: 0)
        BGTaskScheduler.shared.getPendingTaskRequests(completionHandler: { requests in
            result = requests.contains(where: {$0.identifier == Self.identifier})
            semaphore.signal()
        })
        semaphore.wait()
        return result
    }
    
    static func registerTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.identifier, using: nil) { task in
            Self.handleTask(task)
        }
    }
    
    static func scheduleTask() {
        let request = BGAppRefreshTaskRequest(identifier: Self.identifier)
        
        request.earliestBeginDate = Date.now + fetchInterval
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            Logger.atwyLogs.simpleLog("Could not schedule fetch activity (\(String(describing: type(of: Self.self))): \(error)")
        }
    }
    
    static func handleTask(_ task: BGTask) {
        Self.taskOperation()
        
        task.setTaskCompleted(success: true)
    }
}
