//
//  HLSDownloader+AVAssetDownloadDelegate.swift
//  Atwy
//
//  Created by Antoine Bollengier on 21.10.2023.
//

import Foundation
import AVFoundation
import UIKit

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
        DispatchQueue.main.async {
            self.percentComplete = max(newPercentComplete, self.percentComplete)
        }
    }
    
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        self.location = location
    }
    
    //    func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask, willDownloadTo location: URL) {
    //        self.location = location
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
        self.location = location
        let data = try? Data(contentsOf: location)
        try? FileManager.default.removeItem(at: location)
        processEndOfDownload(videoData: data)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite != 0 else { return }
        DispatchQueue.main.async {
            self.percentComplete = max(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite), self.percentComplete)
        }
    }
    
    
    /// Tells the delegate that the task finished transferring data (HLS download).
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard !self.startedEndProcedure else { return /* Already started the end procedure. */ }
        if let error = error {
            print("Finished with error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.percentComplete = 0.0
                self.downloaderState = .failed
            }
            if let location = self.location {
                do {
                    try FileManager.default.removeItem(at: location)
                } catch {
                    print(error)
                }
            }
        } else {
            processEndOfDownload()
        }
    }
    
    func processEndOfDownload(videoData: Data? = nil) {
        self.startedEndProcedure = true
        guard let videoId = self.video?.videoId else {
            print("self.video?.videoId = \(String(describing: self.video?.videoId)) is not defined.")
            DispatchQueue.main.async {
                self.downloaderState = .failed
            }
            return
        }
        guard let location = self.location, let docDir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else { return }
        let newPath: URL
        
        // Normal video
        if let videoData = videoData {
            newPath = URL(string: "\(docDir.absoluteString)\(videoId).mp4")!
            guard FileManager.default.createFile(atPath: newPath.path(), contents: videoData) else {
                print("Couldn't create a new file with video's contents.")
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
                print("started export")
                _ = docDir.startAccessingSecurityScopedResource()
                session?.exportAsynchronously(completionHandler: {
                    semaphore.signal()
                })
                semaphore.wait()
                self.location = newPath
                docDir.stopAccessingSecurityScopedResource()
                print("finished export")
            }
            */

            newPath = URL(string: "\(docDir.absoluteString)\(videoId).movpkg")!
            _ = docDir.startAccessingSecurityScopedResource()
            guard copyVideoAndDeleteOld(location: location, newLocation: newPath) else {
                print("Couldn't copy/remove the new video's contents.")
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
                        print(error)
                    }
                    
                    let asset = AVAsset(url: TSUrl)
                    let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough)
                    session?.outputFileType = .mp4
                    session?.outputURL = MP4URL
                    session?.exportAsynchronously {
                        print("Exported \(TSUrl) at path: \(MP4URL)")
                    }
                }
            }
             */
            docDir.stopAccessingSecurityScopedResource()
        }
        Task {
            let backgroundContext = PersistenceModel.shared.controller.container.newBackgroundContext()
            let videoInfos = try? await self.video?.fetchMoreInfos(youtubeModel: YTM)
            backgroundContext.performAndWait {
                let newVideo = DownloadedVideo(context: backgroundContext)
                newVideo.timestamp = Date()
                newVideo.storageLocation = newPath
                newVideo.title = videoInfos?.videoTitle ?? self.video?.title
                if let thumbnailURL = URL(string: "https://i.ytimg.com/vi/\(videoId)/hqdefault.jpg") {
                    let imageTask = DownloadImageOperation(imageURL: thumbnailURL)
                    imageTask.start()
                    imageTask.waitUntilFinished()
                    if let imageData = imageTask.imageData {
                        newVideo.thumbnail = cropImage(data: imageData)
                    }
                }
                newVideo.timeLength = self.video?.timeLength
                newVideo.timePosted = videoInfos?.timePosted.postedDate
                newVideo.videoId = videoId
                
                for chapter in videoInfos?.chapters ?? [] {
                    guard let startTimeSeconds = chapter.startTimeSeconds else { continue }
                    let chapterEntity = DownloadedVideoChapter(context: backgroundContext)
                    chapterEntity.shortTimeDescription = chapter.timeDescriptions.shortTimeDescription
                    chapterEntity.startTimeSeconds = Int32(startTimeSeconds)
                    if let chapterThumbnailURL = chapter.thumbnail.last?.url {
                        let imageTask = DownloadImageOperation(imageURL: chapterThumbnailURL)
                        imageTask.start()
                        imageTask.waitUntilFinished()
                        chapterEntity.thumbnail = imageTask.imageData
                    } else {
                        chapterEntity.thumbnail = newVideo.thumbnail
                    }
                    chapterEntity.title = chapter.title
                    newVideo.addToChapters(chapterEntity)
                }
                
                if let channelId = self.video?.channel?.channelId {
                    let fetchRequest = DownloadedChannel.fetchRequest()
                    fetchRequest.fetchLimit = 1
                    fetchRequest.predicate = NSPredicate(format: "channelId == %@", channelId)
                    let result = try? backgroundContext.fetch(fetchRequest)
                    
                    if let channel = result?.first {
                        channel.addToVideos(newVideo)
                    } else {
                        let newChannel = DownloadedChannel(context: backgroundContext)
                        newChannel.channelId = channelId
                        newChannel.name = videoInfos?.channel?.name ?? self.video?.channel?.name
                        if let channelThumbnailURL = videoInfos?.channel?.thumbnails.maxFor(3) ?? self.video?.channel?.thumbnails.maxFor(3) {
                            let imageTask = DownloadImageOperation(imageURL: channelThumbnailURL.url)
                            imageTask.start()
                            imageTask.waitUntilFinished()
                            newChannel.thumbnail = imageTask.imageData
                        }
                        newChannel.addToVideos(newVideo)
                    }
                }
                
                newVideo.videoDescription = videoDescription
                do {
                    try backgroundContext.save()
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
                    print("Unresolved error \(nsError), \(nsError.userInfo)")
                    DispatchQueue.main.async {
                        self.downloaderState = .failed
                    }
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
                print("Couldn't delete downloaded asset, error: \(error)")
                print("Creating automatic deletion rule.")
                let policy = AVMutableAssetDownloadStorageManagementPolicy()
                policy.expirationDate = Date()
                AVAssetDownloadStorageManager.shared().setStorageManagementPolicy(policy, for: location)
            }
            self.location = newLocation
            return true
        } catch {
            try? FileManager.default.removeItem(at: location)
            print(error)
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
