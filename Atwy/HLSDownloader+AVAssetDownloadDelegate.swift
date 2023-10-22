//
//  HLSDownloader+AVAssetDownloadDelegate.swift
//  Atwy
//
//  Created by Antoine Bollengier on 21.10.2023.
//

import Foundation
import AVFoundation

/**
 Extend `AssetPersistenceManager` to conform to the `AVAssetDownloadDelegate` protocol.
 */
extension HLSDownloader: AVAssetDownloadDelegate {
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
        var newPercentComplete = 0.0
        for value in loadedTimeRanges {
            let loadedTimeRange: CMTimeRange = value.timeRangeValue
            newPercentComplete +=
                loadedTimeRange.duration.seconds / timeRangeExpectedToLoad.duration.seconds
        }
        DispatchQueue.main.async {
            self.percentComplete = newPercentComplete
        }
        NotificationCenter.default.post(
            name: Notification.Name("DownloadPercentageChanged"),
            object: nil
        )
    }

    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        self.location = location
    }

    /// Tells the delegate that the task finished transferring data.
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("Finished with error: \(error.localizedDescription)")
            percentComplete = 0.0
            downloaderState = .failed
            if let location = self.location {
                do {
                    try FileManager.default.removeItem(at: location)
                } catch {
                    print(error)
                }
            }
        } else {
            if let videoId = self.video?.videoId, let location = self.location {
                Task {
                    /// Moving the download in a safe place.
                    let docDir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                    _ = docDir.startAccessingSecurityScopedResource()
                    let newPath = URL(string: "\(docDir.absoluteString)\(videoId).movpkg")!
                    do {
                        try FileManager.default.copyItem(at: location, to: newPath)
                        docDir.stopAccessingSecurityScopedResource()
                        let policy = AVMutableAssetDownloadStorageManagementPolicy()
                        policy.expirationDate = Date()
                        AVAssetDownloadStorageManager.shared().setStorageManagementPolicy(policy, for: location)
                        self.location = newPath
                        
                        let videoInfos = await self.video?.fetchMoreInfos(youtubeModel: YTM)
                        let newVideo = DownloadedVideo(context: PersistenceModel.shared.context)
                        newVideo.timestamp = Date()
                        newVideo.storageLocation = newPath
                        newVideo.title = videoInfos?.0?.videoTitle ?? self.video?.title
                        if let thumbnailURL = self.video?.thumbnails.last?.url {
                            newVideo.thumbnail = await getImage(from: thumbnailURL)
                        }
                        newVideo.timeLength = self.video?.timeLength
                        newVideo.timePosted = videoInfos?.0?.timePosted.postedDate
                        newVideo.videoId = videoId
                        
                        for chapter in videoInfos?.0?.chapters ?? [] {
                            guard let startTimeSeconds = chapter.startTimeSeconds else { continue }
                            let chapterEntity = DownloadedVideoChapter(context: PersistenceModel.shared.context)
                            chapterEntity.shortTimeDescription = chapter.timeDescriptions.shortTimeDescription
                            chapterEntity.startTimeSeconds = Int32(startTimeSeconds)
                            if let chapterThumbnailURL = chapter.thumbnail.last?.url {
                                chapterEntity.thumbnail = await getImage(from: chapterThumbnailURL)
                            }
                            chapterEntity.title = chapter.title
                            newVideo.addToChapters(chapterEntity)
                        }
                        
                        if let channelId = self.video?.channel?.channelId {
                            let fetchRequest = DownloadedChannel.fetchRequest()
                            fetchRequest.fetchLimit = 1
                            fetchRequest.predicate = NSPredicate(format: "channelId == %@", channelId)
                            let result = try? PersistenceModel.shared.context.fetch(fetchRequest)
                            
                            if let channel = result?.first {
                                channel.addToVideos(newVideo)
                            } else {
                                let newChannel = DownloadedChannel(context: PersistenceModel.shared.context)
                                newChannel.channelId = channelId
                                newChannel.name = videoInfos?.0?.channel?.name ?? self.video?.channel?.name
                                if let channelThumbnailURL = videoInfos?.0?.channel?.thumbnails.maxFor(2) ?? self.video?.channel?.thumbnails.maxFor(2) {
                                    newChannel.thumbnail = await getImage(from: channelThumbnailURL.url)
                                }
                                newChannel.addToVideos(newVideo)
                            }
                        }
                        
                        var counter: Int = 0
                        for videoDescriptionPart in videoInfos?.0?.videoDescription ?? [] {
                            guard let text = videoDescriptionPart.text else { continue }
                            let partEntity = DownloadedDescriptionPart(context: PersistenceModel.shared.context)
                            partEntity.index = Int64(counter)
                            partEntity.text = text
                            switch videoDescriptionPart.role {
                            case .link(let URLRole):
                                partEntity.role = "link"
                                partEntity.data = URLRole.dataRepresentation
                            case .chapter(var startTimeRole):
                                partEntity.role = "chapter"
                                partEntity.data = Data(bytes: &startTimeRole, count: MemoryLayout.size(ofValue: startTimeRole))
                            case .channel(let channelIdRole):
                                partEntity.role = "channel"
                                partEntity.data = channelIdRole.data(using: .utf8)
                            case .video(let videoIdRole):
                                partEntity.role = "video"
                                partEntity.data = videoIdRole.data(using: .utf8)
                            case .playlist(let playlistIdRole):
                                partEntity.role = "playlist"
                                partEntity.data = playlistIdRole.data(using: .utf8)
                            default:
                                break
                            }
                            newVideo.addToDescriptionParts(partEntity)
                            counter += 1
                        }
                        
                        DispatchQueue.main.async {
                            self.percentComplete = 100
                        }
                        
                        do {
                            try PersistenceModel.shared.context.save()
                            
                            DispatchQueue.main.async {
                                self.downloaderState = .success
                                NotificationCenter.default.post(
                                    name: Notification.Name("DownloadPercentageChanged"),
                                    object: nil
                                )
                                NotificationCenter.default.post(
                                    name: Notification.Name("CoreDataChanged"),
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
                    } catch {
                        try? FileManager.default.removeItem(at: location)
                        docDir.stopAccessingSecurityScopedResource()
                        print(error)
                        DispatchQueue.main.async {
                            self.downloaderState = .failed
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.downloaderState = .failed
                }
            }
        }
    }
}
