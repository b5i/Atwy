//
//  HLSDownloader+AVAssetDownloadDelegate.swift
//  Atwy
//
//  Created by Antoine Bollengier on 21.10.2023.
//

import Foundation
import AVFoundation
import UIKit
import OSLog

/**
 Extend `AssetPersistenceManager` to conform to the `AVAssetDownloadDelegate` protocol.
 */
extension HLSDownloader: AVAssetDownloadDelegate, URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
        let expectedSeconds = timeRangeExpectedToLoad.duration.seconds
        guard timeRangeExpectedToLoad.duration.seconds != 0 else { return }
        var newPercentComplete = 0.0
        for value in loadedTimeRanges {
            let loadedTimeRange: CMTimeRange = value.timeRangeValue
            newPercentComplete +=
            loadedTimeRange.duration.seconds / expectedSeconds
        }
        
        self.expectedBytes = (Int(assetDownloadTask.countOfBytesReceived), Int(assetDownloadTask.countOfBytesExpectedToReceive))
        DispatchQueue.main.async {
            self.percentComplete = max(newPercentComplete, self.percentComplete)
        }
    }
        
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, willDownloadTo location: URL) {
        DispatchQueue.main.async {
            self.downloadInfo.downloadLocation = location
        }
    }
    
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        DispatchQueue.main.async {
            self.downloadInfo.downloadLocation = location
        }
    }
    
    //    func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask, willDownloadTo location: URL) {
    //        DispatchQueue.main.async {
    //          self.downloadInfo.downloadLocation = location
    //        }
    //    }
    //
    //    func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange, for mediaSelection: AVMediaSelection) {
    //        var newPercentComplete = 0.0
    //        for value in loadedTimeRanges {
    //            let loadedTimeRange: CMTimeRange = value.timeRangeValue
    //            newPercentComplete +=
    //                loadedTimeRange.duration.seconds / timeRangeExpectedToLoad.duration.seconds
    //        }
    //        DispatchQueue.main.async {
    //            self.percentComplete = max(newPercentComplete, self.percentComplete)
    //        }
    //    }
    //
    
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        self.downloadInfo.downloadLocation = location
        let data = try? Data(contentsOf: location)
        try? FileManager.default.removeItem(at: location)
        processEndOfDownload(videoData: data)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite != 0 else { return }
        self.expectedBytes = (Int(totalBytesWritten), Int(totalBytesExpectedToWrite))
        DispatchQueue.main.async {
            self.percentComplete = max(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite), self.percentComplete)
        }
    }
    
    
    /// Tells the delegate that the task finished transferring data (HLS download).
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard !self.startedEndProcedure else { return /* Already started the end procedure. */ }
        if let error = error {
            Logger.atwyLogs.simpleLog("Finished with error: \(error.localizedDescription)")
            self.expectedBytes = (0, 0)
            DispatchQueue.main.async {
                self.percentComplete = 0.0
                self.downloaderState = .failed
            }
            if let location = self.downloadInfo.downloadLocation {
                do {
                    try FileManager.default.removeItem(at: location)
                } catch {
                    Logger.atwyLogs.simpleLog("Could not remove file \(error.localizedDescription)")
                }
            }
        } else {
            processEndOfDownload()
        }
    }
    
    func processEndOfDownload(videoData: Data? = nil) {
        self.startedEndProcedure = true
        guard let location = self.downloadInfo.downloadLocation, let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            Logger.atwyLogs.simpleLog("Couldn't get the download location or the document directory.")
            DispatchQueue.main.async {
                self.downloaderState = .failed
            }
            return
        }
        let newPath: URL
        
        // Normal video
        if let videoData = videoData {
            newPath = URL(string: "\(docDir.absoluteString)\(self.downloadInfo.video.videoId).mp4")!
            guard FileManager.default.createFile(atPath: newPath.path(), contents: videoData) else {
                Logger.atwyLogs.simpleLog("Couldn't create a new file with video's contents.")
                DispatchQueue.main.async {
                    self.downloaderState = .failed
                }
                return
            }
        } else { // HLS stream download
            /*
            newPath = URL(string: "\(docDir.absoluteString)\(videoId).mp4")!
            let asset = AVAsset(url: location)
            let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough)
            session?.outputFileType = .mp4
            session?.outputURL = newPath
            session?.metadata = [
                createMetdataItem(value: video?.title ?? "", type: .commonIdentifierTitle),
                createMetdataItem(value: video?.title ?? "", type: .quickTimeMetadataTitle),
                createMetdataItem(value: video?.channel?.name ?? "", type: .commonIdentifierArtist),
                createMetdataItem(value: video?.channel?.name ?? "", type: .iTunesMetadataTrackSubTitle),
                createMetdataItem(value: video?.channel?.name ?? "", type: .iTunesMetadataArtist),
                createMetdataItem(value: video?.channel?.name ?? "", type: .quickTimeMetadataArtist)
            ]
            let semaphore = DispatchSemaphore(value: 0)
            let backgroundQueue = DispatchQueue(label: "background_convert\(video?.videoId ?? "")",qos: .background)
            backgroundQueue.sync {
                Logger.atwyLogs.simpleLog("started export")
                _ = docDir.startAccessingSecurityScopedResource()
                session?.exportAsynchronously(completionHandler: {
                    semaphore.signal()
                })
                semaphore.wait()
                self.location = newPath
                docDir.stopAccessingSecurityScopedResource()
                Logger.atwyLogs.simpleLog("finished export")
            }
            */

            newPath = URL(string: "\(docDir.absoluteString)\(self.downloadInfo.video.videoId).movpkg")!
            _ = docDir.startAccessingSecurityScopedResource()
            guard copyVideoAndDeleteOld(location: location, newLocation: newPath) else {
                Logger.atwyLogs.simpleLog("Couldn't copy/remove the new video's contents.")
                try? FileManager.default.removeItem(at: location)
                docDir.stopAccessingSecurityScopedResource()
                DispatchQueue.main.async {
                    self.downloaderState = .failed
                }
                return
            }
            /*
            if let enumerator = FileManager.default.enumerator(atPath: newPath.path()) {
                for case let file as String in enumerator where file.hasSuffix(".frag") {
                    guard 
                        let FragUrl = URL(string: newPath.path() + "/" + file),
                        let TSUrl = URL(string: newPath.path() + "/" + file.dropLast(4).appending("ts")),
                        let MP4URL = URL(string: TSUrl.path().dropLast(2).appending("mp4"))
                    else { continue }
                    do {
                        try FileManager.default.moveItem(atPath: FragUrl.path(), toPath: TSUrl.path())
                    } catch {
                        Logger.atwyLogs.simpleLog("\(error.localizedDescription)")
                    }
                    
                    let asset = AVAsset(url: TSUrl)
                    let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough)
                    session?.outputFileType = .mp4
                    session?.outputURL = MP4URL
                    session?.exportAsynchronously {
                        Logger.atwyLogs.simpleLog("Exported \(TSUrl) at path: \(MP4URL)")
                    }
                }
            }
             */
            docDir.stopAccessingSecurityScopedResource()
        }
        let backgroundContext = PersistenceModel.shared.controller.container.newBackgroundContext()
        backgroundContext.performAndWait {
            let newVideo = DownloadedVideo(context: backgroundContext)
            newVideo.timestamp = Date()
            newVideo.storageLocation = newPath
            newVideo.title = self.downloadInfo.videoInfo?.videoTitle ?? self.downloadInfo.video.title
            if let imageData = self.downloadInfo.thumbnailData {
                newVideo.thumbnail = cropImage(data: imageData)
            }
            newVideo.timeLength = self.downloadInfo.video.timeLength
            newVideo.timePosted = self.downloadInfo.videoInfo?.timePosted.postedDate
            newVideo.videoId = self.downloadInfo.video.videoId
            
            for chapter in self.downloadInfo.chapters {
                newVideo.addToChapters(chapter.getEntity(context: backgroundContext))
            }
            
            if let channelId = self.downloadInfo.video.channel?.channelId {
                let fetchRequest = DownloadedChannel.fetchRequest()
                fetchRequest.fetchLimit = 1
                fetchRequest.predicate = NSPredicate(format: "channelId == %@", channelId)
                let result = try? backgroundContext.fetch(fetchRequest)
                
                if let channel = result?.first {
                    channel.thumbnail = self.downloadInfo.channelThumbnailData
                    channel.addToVideos(newVideo)
                } else {
                    let newChannel = DownloadedChannel(context: backgroundContext)
                    newChannel.channelId = channelId
                    newChannel.name = self.downloadInfo.videoInfo?.channel?.name ?? self.downloadInfo.video.channel?.name
                    newChannel.thumbnail = self.downloadInfo.channelThumbnailData
                    newChannel.addToVideos(newVideo)
                }
            }
            
            newVideo.videoDescription = downloadInfo.videoDescription
            do {
                try backgroundContext.save()
                PersistenceModel.shared.currentData.addDownloadedVideo(videoId: self.downloadInfo.video.videoId, storageLocation: newPath)
                self.expectedBytes = (0, 0)
                DispatchQueue.main.async {
                    self.percentComplete = 100
                    self.downloaderState = .success
                    NotificationCenter.default.post(
                        name: .atwyCoreDataChanged,
                        object: nil
                    )
                }
            } catch {
                let nsError = error as NSError
                Logger.atwyLogs.simpleLog("Unresolved error \(nsError), \(nsError.userInfo)")
                DispatchQueue.main.async {
                    self.downloaderState = .failed
                }
            }
        }
        
        @Sendable func cropImage(data: Data) -> Data? {
            guard let uiImage = UIImage(data: data) else { return nil }
            let portionToCut = (uiImage.size.height - uiImage.size.width * 9/16) / 2
            
            // Scale cropRect to handle images larger than shown-on-screen size
            let cropZone = CGRect(x: 0,
                                  y: portionToCut,
                                  width: uiImage.size.width,
                                  height: uiImage.size.height - portionToCut * 2)
            
            // Perform cropping in Core Graphics
            guard let cutImageRef: CGImage = uiImage.cgImage?.cropping(to: cropZone)
            else {
                return nil
            }
            
            // Return image to UIImage
            let croppedImage: UIImage = UIImage(cgImage: cutImageRef)
            return croppedImage.pngData()
        }
    }
    
    func copyVideoAndDeleteOld(location: URL, newLocation: URL) -> Bool {
        do {
            /// - TODO: Adapt to `AVAssetCache`
            if FileManager.default.fileExists(atPath: newLocation.path()) {
                try FileManager.default.removeItem(at: newLocation)
            }
            try FileManager.default.copyItem(at: location, to: newLocation)
            do {
                try FileManager.default.removeItem(at: location)
            } catch {
                Logger.atwyLogs.simpleLog("Couldn't delete downloaded asset, error: \(error)")
                Logger.atwyLogs.simpleLog("Creating automatic deletion rule.")
                let policy = AVMutableAssetDownloadStorageManagementPolicy()
                policy.expirationDate = Date()
                AVAssetDownloadStorageManager.shared().setStorageManagementPolicy(policy, for: location)
            }
            
            DispatchQueue.main.async {
                self.downloadInfo.downloadLocation = newLocation
            }
            return true
        } catch {
            try? FileManager.default.removeItem(at: location)
            Logger.atwyLogs.simpleLog("\(error.localizedDescription)")
            DispatchQueue.main.async {
                self.downloaderState = .failed
            }
            return false
        }
    }
    
    private func createMetdataItem(value: String, type: AVMetadataIdentifier, key: AVMetadataKey? = nil) -> AVMetadataItem {
        let metadataItem = AVMutableMetadataItem()
        metadataItem.locale = NSLocale.current
        if let key = key {
            metadataItem.key = key as any NSCopying & NSObjectProtocol
        } else {
            metadataItem.identifier = type
        }
        metadataItem.value = value as NSString
        metadataItem.extendedLanguageTag = "und"
        return metadataItem
    }

    private func createArtworkItem(imageData: Data) -> AVMetadataItem {
        let artwork = AVMutableMetadataItem()
        artwork.value = UIImage(data: imageData)!.pngData() as (NSCopying & NSObjectProtocol)?
        artwork.dataType = kCMMetadataBaseDataType_PNG as String
        artwork.identifier = .commonIdentifierArtwork
        artwork.extendedLanguageTag = "und"
        return artwork
    }
}
