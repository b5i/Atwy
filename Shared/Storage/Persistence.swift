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
                print("Unresolved error \(error), \(error.userInfo)")
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
                print("Store with identifier \(storeID) has completed ",
                      "indexing and has processed history token up through \(String(describing: token)).")
            }
        }
    }
}

class PersistenceModel: ObservableObject {

    static let shared = PersistenceModel()

    var controller: PersistenceController
    var context: NSManagedObjectContext
    
    init() {
        controller = PersistenceController.shared
        context = controller.context
        NotificationCenter.default.addObserver(self, selector: #selector(updateContext), name: .atwyCoreDataChanged, object: nil)
    }

    @objc func updateContext() {
        context = controller.context
        self.objectWillChange.send()
    }
    
    public func addToFavorites(video: YTVideo, imageData: Data? = nil) {
        Task {
        let backgroundContext = self.controller.container.newBackgroundContext()
            backgroundContext.performAndWait {
                let newItem = FavoriteVideo(context: backgroundContext)
                newItem.timestamp = Date()
                newItem.videoId = video.videoId
                newItem.title = video.title
                if let imageData = imageData {
                    newItem.thumbnailData = imageData
                } else if let thumbnailURL = URL(string: "https://i.ytimg.com/vi/\(video.videoId)/hqdefault.jpg") {
                    let imageTask = DownloadImageOperation(imageURL: thumbnailURL)
                    imageTask.start()
                    imageTask.waitUntilFinished()
                    backgroundContext.performAndWait {
                        if let imageData = imageTask.imageData {
                            newItem.thumbnailData = cropImage(data: imageData)
                        }
                    }
                }
                
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
                    
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: .atwyCoreDataChanged,
                            object: nil
                        )
                        NotificationCenter.default.post(name: .atwyPopup, object: nil, userInfo: ["PopupType": "addedToFavorites", "PopupData": newItem.thumbnailData as Any])
                    }
                } catch {
                    print("Couldn't add favorite to context, error: \(error)")
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
    
    public func removeFromFavorites(video: YTVideo) {
        let backgroundContext = self.controller.container.newBackgroundContext()
        let fetchRequest = FavoriteVideo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "videoId == %@", video.videoId)
        do {
            let fetchResult = try backgroundContext.fetch(fetchRequest)
            for favorite in fetchResult {
                if let channel = favorite.channel, channel.videosArray.count == 0, channel.favoritesArray.count == 1 {
                    backgroundContext.delete(channel)
                }
                backgroundContext.delete(favorite)
            }
            do {
                try backgroundContext.save()
                
                NotificationCenter.default.post(
                    name: .atwyCoreDataChanged,
                    object: nil
                )
            } catch {
                // handle the Core Data error
                print(error)
            }
        } catch {
            print("Can't fetch the favorites list.")
            print(error)
        }
    }
    
    public func getStorageLocationFor(video: YTVideo) -> String? {
        let backgroundContext = self.controller.container.newBackgroundContext()
        let fetchRequest = DownloadedVideo.fetchRequest()
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "videoId == %@", video.videoId)
        let result = try? backgroundContext.fetch(fetchRequest)
        if let video = result?.first {
            return video.storageLocation.absoluteString
        } else {
            return nil
        }
    }

    public func checkIfFavorite(video: YTVideo) -> Bool {
        let backgroundContext = self.controller.container.newBackgroundContext()
        let fetchRequest = FavoriteVideo.fetchRequest()
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "videoId == %@", video.videoId)
        let result = try? backgroundContext.fetch(fetchRequest)
        return !(result?.isEmpty ?? true)
    }
    
    public func checkIfDownloaded(videoId: String) -> DownloadedVideo? {
        let backgroundContext = self.controller.container.newBackgroundContext()
        let fetchRequest = DownloadedVideo.fetchRequest()
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "videoId == %@", videoId)
        let result = try? backgroundContext.fetch(fetchRequest)
        return result?.first
    }
    
    public func modifyDownloadURLFor(videoId: String, url: String) {
        let backgroundContext = self.controller.container.newBackgroundContext()
        let fetchRequest = DownloadedVideo.fetchRequest()
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "videoId == %@", videoId)
        do {
            let fetchResult = try backgroundContext.fetch(fetchRequest)
            if let newObject = fetchResult.first, let newStorageLocation = URL(string: url) {
                newObject.storageLocation = newStorageLocation
                try backgroundContext.save()

                NotificationCenter.default.post(
                    name: .atwyCoreDataChanged,
                    object: nil
                )
            } else {
                print("no item found")
            }
        } catch {
            print("can't modify to context")
            print(error)
        }
    }
    
    public func removeDownloadFromCoreData(videoId: String) {
        let backgroundContext = self.controller.container.newBackgroundContext()
        let fetchRequest = DownloadedVideo.fetchRequest()
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "videoId == %@", videoId)
        do {
            let fetchResult = try backgroundContext.fetch(fetchRequest)
            if let newObject = fetchResult.first {
                if FileManager.default.fileExists(atPath: newObject.storageLocation.absoluteString) {
                    do {
                        try FileManager.default.removeItem(at: newObject.storageLocation)
                    } catch {
                        print("can't delete file")
                        print(error)
                    }
                }
                if let channel = newObject.channel, channel.favoritesArray.isEmpty, channel.videosArray.count == 1 {
                    backgroundContext.delete(channel)
                }
                backgroundContext.delete(newObject)
                try backgroundContext.save()
                
                NotificationCenter.default.post(
                    name: .atwyCoreDataChanged,
                    object: nil
                )
            } else {
                print("no item found")
            }
            
        } catch {
            print("can't execute fetch request in context")
            print(error)
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
