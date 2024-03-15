//
//  BackgroundFetchOperation.swift
//  Atwy
//
//  Created by Antoine Bollengier on 15.03.2024.
//  Copyright © 2024 Antoine Bollengier. All rights reserved.
//  

import Foundation
import BackgroundTasks

/// A protocol describing an operation that should regularly be done while the app is in background.
@available(iOS 16.1, *)
protocol BackgroundFetchOperation {
    /// The identifier of the fetch operation, for example `Antoine-Bollengier.Atwy.DownloadingsProgressUpdate`.
    static var identifier: String { get }
    
    /// A boolean indicating whether a task of with the same identifier is already scheduled in the `BGTaskScheduler`.
    static var isScheduled: Bool { get }
    
    /// The amount of seconds that a scheduled task has to wait before being executed.
    static var fetchInterval: Double { get }
        
    /// A function to register the task in the `BGTaskScheduler`, should be called during the app initialization.
    static func registerTask()
    
    /// A function to call the handler from ``handleTask(_:)`` in ``fetchInterval`` seconds from the time this function is called, you should ``registerTask()`` before calling this function.
    static func scheduleTask()
    
    /// The actual task that is called by the `BGTaskScheduler`. Should not be overriden except if you need to get access to the task, define ``taskOperation()`` that's called during this function's execution.
    static func handleTask(_ task: BGTask)
    
    /// The custom background task.
    static func taskOperation()
}
