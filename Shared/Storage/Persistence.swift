//
//  Persistence.swift
//  Atwy
//
//  Created by Antoine Bollengier on 19.11.22.
//

import CoreData
import CoreSpotlight
import YouTubeKit
import UIKit
import OSLog


struct PersistenceController {
    static let shared = PersistenceController()
    private (set) var spotlightIndexer: YTSpotlightDelegate?
    
    let container: NSPersistentContainer
    
    let context: NSManagedObjectContext
    
    
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Atwy")
        //        container = NSPersistentCloudKitContainer(name: "Atwy")
        //        try? container.initializeCloudKitSchema(options: [])
        // Add support to group
        let storeUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.Antoine-Bollengier.Atwy")!.appendingPathComponent("Atwy.sqlite")
        let storeDescription = NSPersistentStoreDescription()
        storeDescription.shouldInferMappingModelAutomatically = true
        storeDescription.shouldMigrateStoreAutomatically = true
        storeDescription.url = storeUrl
        storeDescription.type = NSSQLiteStoreType
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        container.persistentStoreDescriptions = [storeDescription]
        
        
        // End of group support
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        let semamphore = DispatchSemaphore(value: 0)
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                Logger.atwyLogs.simpleLog("Unresolved error \(error), \(error.userInfo)")
            }
            semamphore.signal()
        })
        semamphore.wait()
        
        self.spotlightIndexer = YTSpotlightDelegate(forStoreWith: storeDescription, coordinator: container.persistentStoreCoordinator)
        self.spotlightIndexer?.startSpotlightIndexing()
        
        self.context = container.viewContext
        self.context.automaticallyMergesChangesFromParent = true
        self.context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        NotificationCenter.default.addObserver(forName: NSCoreDataCoreSpotlightDelegate.indexDidUpdateNotification,
                                               object: nil,
                                               queue: .main) { (notification) in
            let userInfo = notification.userInfo
            let storeID = userInfo?[NSStoreUUIDKey] as? String
            let token = userInfo?[NSPersistentHistoryTokenKey] as? NSPersistentHistoryToken
            if let storeID = storeID, let token = token {
                Logger.atwyLogs.simpleLog("Store with identifier \(storeID) has completed\nindexing and has processed history token up through \(String(describing: token)).")
            }
        }
         
    }
}

class PersistenceModel: ObservableObject {

    static let shared = PersistenceModel()

    var controller: PersistenceController
    var context: NSManagedObjectContext
    
    var currentData: PersistenceData
    
    init() {
        self.controller = PersistenceController.shared
        self.context = controller.context
        self.currentData = PersistenceData(downloadedVideoIds: [], favoriteVideoIds: [])
        self.currentData = getPersistenceData()
        NotificationCenter.default.addObserver(self, selector: #selector(updateContext), name: .atwyCoreDataChanged, object: nil)
    }

    @objc func updateContext() {
        Task {
            self.context = controller.context
            self.update()
        }
    }
    
    private func update() {
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    public func getPersistenceData() -> PersistenceData {
        let backgroundContext = self.controller.container.newBackgroundContext()
        return backgroundContext.performAndWait {
            let downloadsFetchRequest = DownloadedVideo.fetchRequest()
            downloadsFetchRequest.returnsObjectsAsFaults = false
            
            let favoritesFetchRequest = FavoriteVideo.fetchRequest()
            favoritesFetchRequest.returnsObjectsAsFaults = false
            
            let downloads: [PersistenceData.VideoIdAndLocation]
            let favorites: [String]
            do {
                downloads = try backgroundContext.fetch(downloadsFetchRequest).map({($0.videoId, $0.storageLocation)})
                favorites = try backgroundContext.fetch(favoritesFetchRequest).map({$0.videoId})
            } catch {
                Logger.atwyLogs.simpleLog("Error while refreshing data")
                return self.currentData
            }
            
            return PersistenceData(
                downloadedVideoIds: downloads,
                favoriteVideoIds: favorites
            )
        }
    }
    
    public func addToFavorites(video: YTVideo, imageData: Data? = nil) {
        guard !self.currentData.favoriteVideoIds.contains(where: {$0 == video.videoId}) else { return }
        let backgroundContext = self.controller.container.newBackgroundContext()
        backgroundContext.perform {
            let newItem = FavoriteVideo(context: backgroundContext)
            newItem.timestamp = Date()
            newItem.videoId = video.videoId
            newItem.title = video.title
            
            var thumbnailData: Data?
            if let imageData = imageData {
                thumbnailData = imageData
            } else if let thumbnailURL = URL(string: "https://i.ytimg.com/vi/\(video.videoId)/hqdefault.jpg") {
                let imageTask = DownloadImageOperation(imageURL: thumbnailURL)
                imageTask.start()
                imageTask.waitUntilFinished()
                backgroundContext.performAndWait {
                    if let imageData = imageTask.imageData {
                        thumbnailData = self.cropImage(data: imageData)
                    }
                }
            }
            newItem.thumbnailData = thumbnailData
            
            if let channelId = video.channel?.channelId {
                let fetchRequest = DownloadedChannel.fetchRequest()
                fetchRequest.fetchLimit = 1
                fetchRequest.predicate = NSPredicate(format: "channelId == %@", channelId)
                let result = try? backgroundContext.fetch(fetchRequest)
                
                if let channel = result?.first {
                    channel.addToFavorites(newItem)
                } else {
                    let newChannel = DownloadedChannel(context: backgroundContext)
                    newChannel.channelId = channelId
                    newChannel.name = video.channel?.name
                    if let channelThumbnailURL = video.channel?.thumbnails.last {
                        let imageTask = DownloadImageOperation(imageURL: channelThumbnailURL.url)
                        imageTask.start()
                        imageTask.waitUntilFinished()
                        backgroundContext.performAndWait {
                            newChannel.thumbnail = imageTask.imageData
                        }
                    }
                    newChannel.addToFavorites(newItem)
                }
            }
            
            newItem.timeLength = video.timeLength
            do {
                try backgroundContext.save()
                
                self.currentData.addFavoriteVideo(videoId: video.videoId)
                /*
                    NotificationCenter.default.post(
                        name: .atwyCoreDataChanged,
                        object: nil
                    )
                 */
                self.update()
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .atwyPopup, object: nil, userInfo: ["PopupType": "addedToFavorites", "PopupData": thumbnailData as Any])
                }
            } catch {
                Logger.atwyLogs.simpleLog("Couldn't add favorite to context, error: \(error)")
            }
        }
    }
        
    func cropImage(data: Data) -> Data? {
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
    
    public func removeFromFavorites(video: YTVideo) {
        let backgroundContext = self.controller.container.newBackgroundContext()
        backgroundContext.perform {
            do {
                let request = FavoriteVideo.fetchRequest()
                
                request.predicate = NSPredicate(format: "videoId == %@", video.videoId)

                let result = try backgroundContext.fetch(request)
                
                result.forEach({ backgroundContext.delete($0) })

                try backgroundContext.save()
                
                self.currentData.removeFavoriteVideo(videoId: video.videoId)
                NotificationCenter.default.post(
                    name: .atwyCoreDataChanged,
                    object: nil
                )
                self.update()
            } catch {
                // handle the Core Data error
                Logger.atwyLogs.simpleLog("\(error.localizedDescription)")
            }
        }
    }
    
    public func modifyDownloadURLsFor(videos: [(videoId: String, newLocation: URL)]) {
        self.controller.container.performBackgroundTask({ backgroundContext in
            let fetchRequest = DownloadedVideo.fetchRequest()
            fetchRequest.returnsObjectsAsFaults = false
            do {
                let result = try backgroundContext.fetch(fetchRequest)
                
                for video in videos {
                    guard let videoIndex = self.currentData.downloadedVideoIds.firstIndex(where: {$0.videoId == video.videoId}), let videoObject = result.first(where: {$0.videoId == video.videoId}) else { return }
                    
                    videoObject.storageLocation = video.newLocation
                    self.currentData.replaceDownloadedVideoURLAtIndex(videoIndex, by: video.newLocation)
                    
                }
                
                try backgroundContext.save()
                
                NotificationCenter.default.post(
                    name: .atwyCoreDataChanged,
                    object: nil
                )
                self.update()
            } catch {
                Logger.atwyLogs.simpleLog("Couldn't update URLs: \(error)")
            }
        })
    }

    public func checkIfFavorite(video: YTVideo) -> Bool {
        return self.currentData.favoriteVideoIds.contains(where: {$0 == video.videoId})
    }
        
    public func getDownloadedVideo(videoId: String) -> WrappedDownloadedVideo? {
        let backgroundContext = self.controller.container.newBackgroundContext()
        return backgroundContext.performAndWait {
            let fetchRequest = DownloadedVideo.fetchRequest()
            fetchRequest.returnsObjectsAsFaults = false
            fetchRequest.fetchLimit = 1
            fetchRequest.predicate = NSPredicate(format: "videoId == %@", videoId)
            let result = try? backgroundContext.fetch(fetchRequest)
            return result?.first?.wrapped
        }
    }
    
    public func isVideoDownloaded(videoId: String) -> PersistenceData.VideoIdAndLocation? {
        return self.currentData.downloadedVideoIds.first(where: {$0.videoId == videoId})
    }
    
    public func removeDownloadFromCoreData(videoId: String) {
        self.removeDownloadsFromCoreData(videoIds: [videoId])
    }
    
    public func removeDownloadsFromCoreData(videoIds: [String]) {
        let backgroundContext = self.controller.container.newBackgroundContext()
        backgroundContext.perform {
            let fetchRequest = DownloadedVideo.fetchRequest()
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                let result = try backgroundContext.fetch(fetchRequest)
                                
                for video in result {
                    if videoIds.contains(video.videoId) {
                        if FileManager.default.fileExists(atPath: video.storageLocation.path()) {
                            FileManagerModel.shared.removeVideoDownload(videoId: video.videoId)
                        }
                        
                        if let channel = video.channel, channel.favoritesArray.isEmpty, channel.videosArray.count == 1 {
                            backgroundContext.delete(channel)
                        }
                        backgroundContext.delete(video)
                        
                        self.currentData.removeDownloadedVideo(videoId: video.videoId)
                    }
                }
                
                try backgroundContext.save()
                
                
                NotificationCenter.default.post(
                    name: .atwyCoreDataChanged,
                    object: nil
                )
                 
                self.update()
            } catch {
                Logger.atwyLogs.simpleLog("\(error.localizedDescription)")
            }
        }
    }
    
    struct PersistenceData: Identifiable {
        typealias VideoIdAndLocation = (videoId: String, storageLocation: URL)
        
        private(set) var id = UUID()
        
        private(set) var downloadedVideoIds: [VideoIdAndLocation]
        
        private(set) var favoriteVideoIds: [String]
        
        mutating func addDownloadedVideo(videoId: String, storageLocation: URL) {
            self.downloadedVideoIds.append((videoId, storageLocation))
            self.id = UUID()
        }
        
        mutating func removeDownloadedVideo(videoId: String) {
            self.downloadedVideoIds.removeAll(where: {$0.videoId == videoId})
            self.id = UUID()
        }
        
        mutating func replaceDownloadedVideoURLAtIndex(_ index: Int, by newStorageLocation: URL) {
            if downloadedVideoIds.count > index {
                self.downloadedVideoIds[index].storageLocation = newStorageLocation
                self.id = UUID()
            }
        }
        
        mutating func addFavoriteVideo(videoId: String) {
            self.favoriteVideoIds.append(videoId)
            self.id = UUID()
        }
        
        mutating func removeFavoriteVideo(videoId: String) {
            self.favoriteVideoIds.removeAll(where: {$0 == videoId})
            self.id = UUID()
        }
    }
}

class YTSpotlightDelegate: NSCoreDataCoreSpotlightDelegate {
    override func domainIdentifier() -> String {
        return "Antoine-Bollengier.Atwy.spotlightData"
    }

    override func indexName() -> String? {
        return "spotlight-indexData"
    }

    override func attributeSet(for object: NSManagedObject) -> CSSearchableItemAttributeSet? {
        if let item = object as? DownloadedVideo {
            let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
            attributeSet.identifier = item.videoId
            attributeSet.displayName = item.title
            attributeSet.artist = item.channel?.name
            attributeSet.contentDescription = item.videoDescription
            attributeSet.thumbnailData = item.thumbnail
            attributeSet.containerDisplayName = "Downloaded Video"
            if attributeSet.keywords != nil {
                attributeSet.keywords?.append(contentsOf: [item.title, item.channel?.name, item.videoDescription].compactMap({$0}))
            } else {
                attributeSet.keywords = [item.title, item.channel?.name, item.videoDescription].compactMap({$0})
            }
            return attributeSet
        } else if let channel = object as? DownloadedChannel {
            let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
            attributeSet.identifier = channel.channelId
            attributeSet.displayName = channel.name
            attributeSet.thumbnailData = channel.thumbnail
            attributeSet.containerDisplayName = "Channel"
            if attributeSet.keywords != nil {
                attributeSet.keywords?.append(contentsOf: [channel.name].compactMap({$0}))
            } else {
                attributeSet.keywords = [channel.name].compactMap({$0})
            }
            return attributeSet
        } else if let favorite = object as? FavoriteVideo {
            let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
            attributeSet.identifier = favorite.videoId
            attributeSet.displayName = favorite.title
            attributeSet.artist = favorite.channel?.name
            attributeSet.thumbnailData = favorite.thumbnailData
            attributeSet.containerDisplayName = "Favorite"
            if attributeSet.keywords != nil {
                attributeSet.keywords?.append(contentsOf: [favorite.title, favorite.channel?.name].compactMap({$0}))
            } else {
                attributeSet.keywords = [favorite.title, favorite.channel?.name].compactMap({$0})
            }
            return attributeSet
        } else if let chapter = object as? DownloadedVideoChapter {
            let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
            attributeSet.identifier = (chapter.video?.videoId ?? "")+String(chapter.startTimeSeconds)
            attributeSet.displayName = (chapter.title ?? "") + " - " + (chapter.video?.title ?? "")
            attributeSet.artist = chapter.video?.channel?.name
            attributeSet.thumbnailData = chapter.thumbnail
            attributeSet.containerDisplayName = "Video Chapter"
            if attributeSet.keywords != nil {
                attributeSet.keywords?.append(contentsOf: [chapter.title].compactMap({$0}))
            } else {
                attributeSet.keywords = [chapter.title].compactMap({$0})
            }
            return attributeSet
        }
        return nil
    }
}
