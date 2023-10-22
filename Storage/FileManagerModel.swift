//
//  FileManagerModel.swift
//  Atwy
//
//  Created by Antoine Bollengier on 21.10.2023.
//

import Foundation

class FileManagerModel: ObservableObject {
    static let shared = FileManagerModel()
    
    @Published var filesRemovedProgress: Bool = false
    
    
    func fetchNewDownloadedVideosPaths() {
#if !os(macOS)
        let (currentVideos, fetchResult) = getDownloadedVideosPath()
        for video in fetchResult {
            let potentialPath = currentVideos.first(where: {$0.absoluteString.contains(video.videoId)})
            if let potentialPath = potentialPath {
                PersistenceModel.shared.modifyDownloadURLFor(videoId: video.videoId, url: potentialPath.absoluteString)
            } else {
                PersistenceModel.shared.removeDownloadFromCoreData(videoId: video.videoId)
            }
        }
#endif
    }
    
    func getDownloadedVideosPath() -> ([URL], [DownloadedVideo]) {
        do {
            var directoryContents: [URL] = []
            let docDir = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            guard let userVideos = FileManager.default.enumerator(at: docDir, includingPropertiesForKeys: [], options: [.skipsSubdirectoryDescendants]) else { return ([], []) }
            
            
//            for video in (userVideos?.filter({!(($0 as? URL)?.absoluteString.contains("Trash") ?? true)})) ?? [] {
            for video in userVideos.compactMap({ $0 as? URL }) {
                directoryContents.append(video)
            }
            let coreDataVideos = removeNonDownloadedVideos(fileList: &directoryContents)
            return (directoryContents, coreDataVideos)
        } catch {
            print(error)
            return ([], [])
        }
    }
    
    func removeNonDownloadedVideos(fileList: inout [URL]) -> [DownloadedVideo] {
        let fetchRequest = DownloadedVideo.fetchRequest()
        do {
            let fetchResult = try PersistenceModel.shared.context.fetch(fetchRequest)
            let newFileList = fileList
            for (index, file) in newFileList.enumerated() where file.pathExtension == "movpkg" {
                do {
                    if !fetchResult.contains(where: {$0.videoId == file.lastPathComponent.replacingOccurrences(of: ".movpkg", with: "")}) {
                        try FileManager.default.removeItem(at: file)
                        fileList.remove(at: index - newFileList.count + fileList.count)
                    }
                } catch {
                    print("Couldn't delete file: \(error.localizedDescription)")
                }
            }
            DispatchQueue.main.async {
                self.filesRemovedProgress = true
            }
            return fetchResult
        } catch {
            print(error)
        }
        return []
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
            print(error)
            return ""
        }
    }
}
