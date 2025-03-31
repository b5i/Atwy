//
//  FileManagerModel.swift
//  Atwy
//
//  Created by Antoine Bollengier on 21.10.2023.
//  Copyright © 2023-2025 Antoine Bollengier. All rights reserved.
//

import Foundation
import OSLog

class FileManagerModel: ObservableObject {    
    static let shared = FileManagerModel()
    
    @Published var filesRemovedProgress: Bool = false
    
    
    func updateNewDownloadPathsAndCleanUpFiles() {
#if !os(macOS)
        let (currentVideos, fetchResult) = getDownloadedVideosPathAndCleanUp()
        var downloadsToModify: [(videoId: String, newLocation: URL)] = []
        var downloadsToRemove: [String] = [] // array of videoIds
        for video in fetchResult {
            let potentialPath = currentVideos.first(where: {$0.absoluteString.contains(video.videoId)})
            if let newPath = potentialPath {
                if newPath != video.storageLocation {
                    downloadsToModify.append((video.videoId, newPath))
                }
            } else {
                downloadsToRemove.append(video.videoId)
            }
        }
        
        PersistenceModel.shared.removeDownloadsFromCoreData(videoIds: downloadsToRemove)
        PersistenceModel.shared.modifyDownloadURLsFor(videos: downloadsToModify)
#endif
    }
    
    func getDownloadedVideosPathAndCleanUp() -> (newURLs: [URL], currentStates: [PersistenceModel.PersistenceData.VideoIdAndLocation]) {
        var files = getAllFiles()
        let coreDataVideos = removeNonDownloadedVideos(fileList: &files)
        return (files, coreDataVideos)
    }
    
    func removeNonDownloadedVideos(fileList: inout [URL]) -> [PersistenceModel.PersistenceData.VideoIdAndLocation] {
        let downloadedVideoIds = PersistenceModel.shared.currentData.downloadedVideoIds
        var newFileList: [URL] = []
        for (_, file) in fileList.enumerated() where file.pathExtension == "movpkg" {
            if !downloadedVideoIds.contains(where: {$0.videoId == file.lastPathComponent.replacingOccurrences(of: ".movpkg", with: "")}) {
                do {
                    Logger.atwyLogs.simpleLog("Removing file: \(file.lastPathComponent), because it's not in CoreData.")
                    try FileManager.default.removeItem(at: file)
                } catch {
                    Logger.atwyLogs.simpleLog("Couldn't delete file: \(error.localizedDescription)")
                }
            } else {
                newFileList.append(file)
            }
        }
        DispatchQueue.main.async {
            self.filesRemovedProgress = true
        }
        return downloadedVideoIds
    }
    
    func getAllFiles() -> [URL] {
        do {
            var directoryContents: [URL] = []
            let docDir = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            guard let userVideos = FileManager.default.enumerator(at: docDir, includingPropertiesForKeys: [], options: [.skipsSubdirectoryDescendants]) else { return [] }
            
            
            for video in userVideos.compactMap({ $0 as? URL }) {
                directoryContents.append(video)
            }
            return directoryContents
        } catch {
            Logger.atwyLogs.simpleLog("\(error.localizedDescription)")
            return []
        }
    }
    
    func removeVideoDownload(videoId: String) {
        for file in getAllFiles() where (file.pathExtension == "movpkg" || file.pathExtension == "mp4") && file.lastPathComponent.contains(videoId) {
            do {
                try FileManager.default.removeItem(at: file)
            } catch {
                Logger.atwyLogs.simpleLog("Couldn't delete file: \(error.localizedDescription)")
            }
        }
    }
    
    func getNewAppIdentifier() -> String {
        do {
            let docDir = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let appIdentifier = docDir.absoluteString.split(separator: "Application/")[1].split(separator: "/Documents")[0]
            return String(appIdentifier)
        } catch {
            Logger.atwyLogs.simpleLog("\(error.localizedDescription)")
            return ""
        }
    }
}
