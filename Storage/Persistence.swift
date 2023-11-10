//
//  Persistence.swift
//  Atwy
//
//  Created by Antoine Bollengier on 19.11.22.
//

import CoreData
import CoreSpotlight
import YouTubeKit

struct PersistenceController {
    static let shared = PersistenceController()
    private (set) var spotlightIndexer: YTSpotlightDelegate?

    let container: NSPersistentContainer
    
    let context: NSManagedObjectContext
    
    let backgroundContext: NSManagedObjectContext

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Atwy")
//        container = NSPersistentCloudKitContainer(name: "Atwy")
//        try? container.initializeCloudKitSchema(options: [])
        // Add support to group
        let storeUrl =  FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.Antoine-Bollengier.Atwy")!.appendingPathComponent("Atwy.sqlite")
        let description = NSPersistentStoreDescription()
        description.shouldInferMappingModelAutomatically = true
        description.shouldMigrateStoreAutomatically = true
        description.url = storeUrl
        description.type = NSSQLiteStoreType
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.Antoine-Bollengier.Atwy")!.appendingPathComponent("Atwy.sqlite"))]
        // End of group support
//        self.context = container.newBackgroundContext()
        self.context = container.viewContext
        self.backgroundContext = container.newBackgroundContext()
        self.context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        spotlightIndexer = YTSpotlightDelegate(forStoreWith: description, coordinator: container.persistentStoreCoordinator)
        print(spotlightIndexer?.isIndexingEnabled)
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
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
        })
        self.context.automaticallyMergesChangesFromParent = true

        let center = NotificationCenter.default
        let queue = OperationQueue.main
        let spotlightUpdateObserver = center.addObserver(
        forName: NSCoreDataCoreSpotlightDelegate.indexDidUpdateNotification, object: nil, queue: queue
        ) { (notification) in
            let userInfo = notification.userInfo
            let storeID = userInfo?[NSStoreUUIDKey] as? String
            let token = userInfo? [NSPersistentHistoryTokenKey] as? NSPersistentHistoryToken
            if let storeID = storeID, let token = token {
                print("Store with identifier \(storeID) has completed indexing and has processed history token up through \(String(describing: token)).")
            }
        }
//        spotlightIndexer?.startSpotlightIndexing()

    }
}

class PersistenceModel: ObservableObject {

    static let shared = PersistenceModel()

    var controller: PersistenceController
    var context: NSManagedObjectContext
    var backgroundContext: NSManagedObjectContext
    
    init() {
        controller = PersistenceController.shared
        context = controller.context
        backgroundContext = controller.backgroundContext
        NotificationCenter.default.addObserver(self, selector: #selector(updateContext), name: Notification.Name("CoreDataChanged"), object: nil)
    }

    @objc func updateContext() {
        context = controller.context
        self.objectWillChange.send()
    }
    
    public func addToFavorites(video: YTVideo, imageData: Data? = nil) {
        Task {
            let newItem = FavoriteVideo(context: PersistenceModel.shared.context)
            newItem.timestamp = Date()
            newItem.videoId = video.videoId
            newItem.title = video.title

            if let imageData = imageData {
                newItem.thumbnailData = imageData
            } else if let thumbnailURL = video.thumbnails.last?.url {
                newItem.thumbnailData = await getImage(from: thumbnailURL)
            }
            
            if let channelId = video.channel?.channelId {
                let fetchRequest = DownloadedChannel.fetchRequest()
                fetchRequest.fetchLimit = 1
                fetchRequest.predicate = NSPredicate(format: "channelId == %@", channelId)
                let result = try? self.context.fetch(fetchRequest)
                
                if let channel = result?.first {
                    channel.addToFavorites(newItem)
                } else {
                    let newChannel = DownloadedChannel(context: PersistenceModel.shared.context)
                    newChannel.channelId = channelId
                    newChannel.name = video.channel?.name
                    if let channelThumbnailURL = video.channel?.thumbnails.first {
                        newChannel.thumbnail = await getImage(from: channelThumbnailURL.url)
                    }
                    newChannel.addToFavorites(newItem)
                }
            }
            
            newItem.timeLength = video.timeLength
            
            DispatchQueue.main.async {
                do {
                    try self.context.save()
                    
                    NotificationCenter.default.post(
                        name: Notification.Name("CoreDataChanged"),
                        object: nil
                    )
                    PopupsModel.shared.showPopup(.addedToFavorites, data: newItem.thumbnailData)
                } catch {
                    print("Couldn't add favorite to context, error: \(error)")
                }
            }
        }
    }
    
    public func getStorageLocationFor(video: YTVideo) -> String? {
        let fetchRequest = DownloadedVideo.fetchRequest()
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "videoId == %@", video.videoId)
        let result = try? self.context.fetch(fetchRequest)
        if let video = result?.first {
            return video.storageLocation.absoluteString
        } else {
            return nil
        }
    }

    public func checkIfFavorite(video: YTVideo) -> Bool {
        let fetchRequest = FavoriteVideo.fetchRequest()
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "videoId == %@", video.videoId)
        let result = try? self.context.fetch(fetchRequest)
        return !(result?.isEmpty ?? true)
    }
    
    public func modifyDownloadURLFor(videoId: String, url: String) {
        let fetchRequest = DownloadedVideo.fetchRequest()
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "videoId == %@", videoId)
        do {
            let fetchResult = try self.context.fetch(fetchRequest)
            if let newObject = fetchResult.first, let newStorageLocation = URL(string: url) {
                newObject.storageLocation = newStorageLocation
                try self.context.save()

                NotificationCenter.default.post(
                    name: Notification.Name("CoreDataChanged"),
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
        let fetchRequest = DownloadedVideo.fetchRequest()
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "videoId == %@", videoId)
        do {
            let fetchResult = try self.context.fetch(fetchRequest)
            if let newObject = fetchResult.first {
                if FileManager.default.fileExists(atPath: newObject.storageLocation.path()) {
                    do {
                        try FileManager.default.removeItem(at: newObject.storageLocation)
                    } catch {
                        print("can't delete file")
                        print(error)
                    }
                }
                if let channel = newObject.channel, channel.favoritesArray.isEmpty, channel.videosArray.count == 1 {
                    self.context.delete(channel)
                }
                self.context.delete(newObject)
                try self.context.save()
                
                NotificationCenter.default.post(
                    name: Notification.Name("CoreDataChanged"),
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
            return attributeSet
        } else if let channel = object as? DownloadedChannel {
            let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
            attributeSet.identifier = channel.channelId
            attributeSet.displayName = channel.name
            attributeSet.thumbnailData = channel.thumbnail
            return attributeSet
        } else if let favorite = object as? FavoriteVideo {
            let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
            attributeSet.identifier = favorite.videoId
            attributeSet.displayName = favorite.title
            attributeSet.artist = favorite.channel?.name
            attributeSet.thumbnailData = favorite.thumbnailData
            return attributeSet
        }
        return nil
    }
}
