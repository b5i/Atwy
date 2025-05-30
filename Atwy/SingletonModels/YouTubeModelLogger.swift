//
//  YouTubeModelLogger.swift
//  Atwy
//
//  Created by Antoine Bollengier on 07.03.2024.
//  Copyright © 2024-2025 Antoine Bollengier. All rights reserved.
//  

import Foundation
import YouTubeKit
import OSLog

class YouTubeModelLogger: RequestsLogger, ObservableObject {
    static let shared = YouTubeModelLogger()
    
    @Published var loggedTypes: [any YouTubeResponse.Type]? = nil
    
    @Published var logs: [any GenericRequestLog] = []
    
    @Published var isLogging: Bool = false
    
    @Published var maximumCacheSize: Int? = nil
    
    init() {
        self.clearLocalLogFiles()
        DispatchQueue.main.async {
            self.isLogging = PreferencesStorageModel.shared.isLoggerActivated
            self.maximumCacheSize = PreferencesStorageModel.shared.loggerCacheLimit
        }
    }
    
    func startLogging() {
        DispatchQueue.main.async {
            self.isLogging = true
        }
    }
    
    func stopLogging() {
        DispatchQueue.main.async {
            self.isLogging = false
        }
    }
    
    
    func setCacheSize(_ size: Int?) {
        DispatchQueue.main.async {
            self.maximumCacheSize = size
            if let size = size {
                self.removeFirstLogsWith(limit: size)
            }
        }
    }
    
    
    func addLog(_ log: any GenericRequestLog) {
        @Sendable func compareTypes<T: GenericRequestLog, U: YouTubeResponse>(log1: T, log2: U.Type) -> Bool {
            let newRequest: RequestLog<U>
            return type(of: log1) == type(of: newRequest)
        }
        
        DispatchQueue.main.async {
            guard self.isLogging, (self.maximumCacheSize ?? 1) > 0 else { return }
            guard (self.loggedTypes?.contains(where: { compareTypes(log1: log, log2: $0) }) ?? true) else { return }
            if let maximumCacheSize = self.maximumCacheSize {
                self.removeFirstLogsWith(limit: max(maximumCacheSize - 1, 0))
            }
            self.logs.append(log)
        }
    }
    
    
    func clearLogs() {
        DispatchQueue.main.async {
            self.logs.removeAll()
        }
    }
    
    func clearLogsWithIds(_ ids: [UUID]) {
        DispatchQueue.main.async {
            for idToRemove in ids {
                self.logs.removeAll(where: {$0.id == idToRemove})
            }
        }
    }
    
    func clearLogWithId(_ id: UUID) {
        self.clearLogsWithIds([id])
    }
    
    private func removeFirstLogsWith(limit maxCacheSize: Int) {
        let logsCount = self.logs.count
        let maxCacheSize = max(0, maxCacheSize)
        if logsCount > maxCacheSize {
            self.logs.removeFirst(abs(maxCacheSize - logsCount))
        }
    }
    
    func clearLocalLogFiles() {
        Task {
            guard let baseDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("logs", isDirectory: true) else { return }
            
            do {
                let fileURLs = try FileManager.default.contentsOfDirectory(at: baseDirectory,
                                                                           includingPropertiesForKeys: nil,
                                                                           options: .skipsHiddenFiles)
                for fileURL in fileURLs where fileURL.pathExtension == "zip" {
                    try FileManager.default.removeItem(at: fileURL)
                }
            } catch { Logger.atwyLogs.simpleLog("Error removing log file: \(error)") }
        }
    }
    
    /// Returns nil if the log does not exist
    func exportLog(withId logId: UUID, showCredentials: Bool) -> URL? {
        guard let log = logs.first(where: {$0.id == logId}) else { return nil }
        return createZip(withName: logId.uuidString, files: [
            ("infos", Self.getTextForSelection(log: log, category: .baseInfos, showCredentials: showCredentials)),
            ("request", Self.getTextForSelection(log: log, category: .requestInfos, showCredentials: showCredentials)),
            ("responseData", Self.getTextForSelection(log: log, category: .responseData, showCredentials: showCredentials)),
            ("result", Self.getTextForSelection(log: log, category: .response, showCredentials: showCredentials))
        ])
    }
    
    static func getTextForSelection(log: any GenericRequestLog, category: LogCategory, showCredentials: Bool) -> String {
        switch category {
        case .baseInfos:
            return """
                    id: \(log.id.uuidString)
                    date: \(log.date.formatted())
                    expectedResultType: \(String(describing: log.expectedResultType))
                    providedParameters: \(String(describing: log.providedParameters))
                    """
        case .requestInfos:
            return """
                    url: \(String(describing: log.request?.url))
                    httpFields: \(showCredentials ? String(describing: log.request?.allHTTPHeaderFields) : "Credentials hidden")
                    httpBody: \(showCredentials ? String(decoding: log.request?.httpBody ?? Data(), as: UTF8.self) : "Credentials hidden")
                    httpMethod: \(String(describing: log.request?.httpMethod))
                    cachePolicy: \(String(describing: log.request?.cachePolicy.rawValue))
                    """
        case .responseData:
            return String(decoding: log.responseData ?? Data(), as: UTF8.self)
        case .response:
            let newLog = log
            return self.getResultString(fromLog: newLog)
        }
    }
    
    static func getResultString<L: GenericRequestLog>(fromLog log: L) -> String {
        switch log.result {
        case .success(let response):
            return String(describing: response)
        case .failure(let error):
            return "Error: \(String(describing: error))"
        }
    }
    
    enum LogCategory {
        case baseInfos
        case requestInfos
        case responseData
        case response
    }
    
    /// Name should not finish with .zip, fileName from the files should also not have an extension
    private func createZip(withName name: String, files: [(fileName: String, contents: String)]) -> URL? {
        guard let baseDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("logs", isDirectory: true).appendingPathComponent(name, isDirectory: true) else { return nil }
        do {
            
            try FileManager.default.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
            
            let zipName = "\(name).zip"
            
            for (fileName, contents) in files {
                try contents.write(to: baseDirectory.appendingPathComponent(fileName + ".txt"), atomically: false, encoding: .utf8)
            }
            
            //https://forums.developer.apple.com/forums/thread/688165
            // this will hold the URL of the zip file
            var archiveUrl: URL?
            // if we encounter an error, store it here
            var coordinatorError: NSError? = nil
            
            let coordinator = NSFileCoordinator()
            // zip up the root directory
            // this method is synchronous and the block will be executed before it returns
            // if the method fails, the block will not be executed though
            // if you expect the archiving process to take long, execute it on another queue
            
            coordinator.coordinate(readingItemAt: baseDirectory, options: [.forUploading], error: &coordinatorError) { (zipUrl) in
                do {
                    // zipUrl points to the zip file created by the coordinator
                    // zipUrl is valid only until the end of this block, so we move the file to a temporary folder
                    let tmpUrl = try FileManager.default.url(
                        for: .itemReplacementDirectory,
                        in: .userDomainMask,
                        appropriateFor: zipUrl,
                        create: true
                    ).appendingPathComponent(zipName, isDirectory: false)
                    try FileManager.default.copyItem(at: zipUrl, to: tmpUrl)
                    
                    // store the URL so we can use it outside the block
                    archiveUrl = tmpUrl
                    
                    try FileManager.default.removeItem(at: baseDirectory)
                } catch {
                    Logger.atwyLogs.simpleLog("\(error.localizedDescription)")
                }
            }
            
            
        
            return archiveUrl
        } catch {
            Logger.atwyLogs.simpleLog("\(error.localizedDescription)")
        }
        
        return nil
    }
}
