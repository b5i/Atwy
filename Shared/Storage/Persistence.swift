//
//  Persistence.swift
//  Atwy
//
//  Created by Antoine Bollengier on 19.11.22.
//  Copyright © 2022-2026 Antoine Bollengier. All rights reserved.
//

import CoreData
import CoreSpotlight
import YouTubeKit
import UIKit
import OSLog


struct PersistenceController {
    static let shared = PersistenceController()
    private(set) var spotlightIndexer: YTSpotlightDelegate?
    
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
    
    private(set) var currentData: PersistenceData {
        didSet {
            DispatchQueue.main.async {
                self.pCurrentData = self.currentData
            }
        }
    }
    
    @Published private(set) var pCurrentData: PersistenceData
    
    private var videoIdsAddedToFavorites: [String] = []
    
    init() {
        self.controller = PersistenceController.shared
        self.context = controller.context
        self.currentData = PersistenceData(downloadedVideoIds: [], favoriteVideoIds: [], searchHistory: [], watchedVideos: [:])
        self.currentData = .init(downloadedVideoIds: [], favoriteVideoIds: [], searchHistory: [], watchedVideos: [:])
        self.pCurrentData = .init(downloadedVideoIds: [], favoriteVideoIds: [], searchHistory: [], watchedVideos: [:])
        updatePersistenceData()
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
    
    public func updatePersistenceData() {
        Task.detached {
            let backgroundContext = self.controller.container.newBackgroundContext()
            backgroundContext.performAndWait {
                let downloadsFetchRequest = DownloadedVideo.fetchRequest()
                downloadsFetchRequest.returnsObjectsAsFaults = false
                
                let favoritesFetchRequest = FavoriteVideo.fetchRequest()
                favoritesFetchRequest.returnsObjectsAsFaults = false
                
                let searchHistoryFetchRequest = SearchHistory.fetchRequest()
                favoritesFetchRequest.returnsObjectsAsFaults = false
                
                let watchedVideosFetchRequest = WatchedVideo.fetchRequest()
                favoritesFetchRequest.returnsObjectsAsFaults = false
                
                let downloads: [PersistenceData.VideoIdAndLocation]
                let favorites: [String]
                let searchHistory: [PersistenceData.Search]
                let watchedVideos: Dictionary<String, PersistenceData.WatchedVideoData>
                do {
                    downloads = try backgroundContext.fetch(downloadsFetchRequest).map({($0.videoId, $0.storageLocation)})
                    favorites = try backgroundContext.fetch(favoritesFetchRequest).map(\.videoId)
                    searchHistory = try backgroundContext.fetch(searchHistoryFetchRequest).compactMap {
                        guard let query = $0.query, let timestamp = $0.timestamp, let uuid = $0.uuid else { return nil }
                        return PersistenceData.Search(query: query, timestamp: timestamp, uuid: uuid)
                    }
                    .sorted(by: {$0.timestamp > $1.timestamp})
                    var watchedVideosArray = try backgroundContext.fetch(watchedVideosFetchRequest).map({ ($0.videoId, ($0.watchedUntil, $0.watchedPercentage)) })
                    watchedVideos = Dictionary(watchedVideosArray, uniquingKeysWith: { return $1 })
                    
                } catch {
                    Logger.atwyLogs.simpleLog("Error while refreshing data")
                    return
                }
                
                let tempData = self.currentData
                
                self.currentData = PersistenceData(
                    downloadedVideoIds: downloads,
                    favoriteVideoIds: favorites,
                    searchHistory: searchHistory,
                    watchedVideos: watchedVideos
                )
                
                tempData.searchHistory.forEach { self.currentData.addSearch($0) }
                tempData.downloadedVideoIds.forEach { self.currentData.addDownloadedVideo(videoId: $0.videoId, storageLocation: $0.storageLocation) }
                tempData.favoriteVideoIds.forEach { self.currentData.addFavoriteVideo(videoId: $0) }
                watchedVideos.forEach { self.currentData.addOrUpdateWatchedVideo(videoId: $0.key, watchedUntil: $0.value.watchedUntil, watchedPercentage: $0.value.watchedPercentage) }
            }
            FileManagerModel.shared.updateNewDownloadPathsAndCleanUpFiles()
        }
    }
    
    public func addSearch(_ search: PersistenceData.Search) {
        guard PreferencesStorageModel.shared.searchHistoryEnabled else { return }
        if let lastSameQuery = self.currentData.searchHistory.first(where: {$0.query == search.query}) {
            let backgroundContext = self.controller.container.newBackgroundContext()
            backgroundContext.perform {
                do {
                    let request = NSFetchRequest<SearchHistory>(entityName: "SearchHistory")
                    
                    request.predicate = NSPredicate(format: "uuid == %@", lastSameQuery.uuid as CVarArg)
                    request.fetchLimit = 1

                    let result = try backgroundContext.fetch(request)
                    
                    result.first?.timestamp = search.timestamp

                    try backgroundContext.save()
                    
                    self.currentData.replaceSearchTimestamp(with: search.timestamp, uuid: lastSameQuery.uuid)
                    self.update()
                } catch {
                    // handle the Core Data error
                    Logger.atwyLogs.simpleLog("\(error.localizedDescription)")
                }
            }
        } else {
            let backgroundContext = self.controller.container.newBackgroundContext()
            backgroundContext.perform {
                let newItem = SearchHistory(context: backgroundContext)
                newItem.timestamp = search.timestamp
                newItem.query = search.query
                newItem.uuid = search.uuid
                do {
                    try backgroundContext.save()
                    
                    self.currentData.addSearch(search)
                    self.update()
                } catch {
                    Logger.atwyLogs.simpleLog("Couldn't add search to context, error: \(error)")
                }
            }
        }
    }
    
    public func removeSearchHistory() {
        let backgroundContext = self.controller.container.newBackgroundContext()
        backgroundContext.performAndWait {
            do {
                let request = NSFetchRequest<SearchHistory>(entityName: "SearchHistory")
                
                let result = try backgroundContext.fetch(request)
                
                result.forEach { backgroundContext.delete($0) }

                try backgroundContext.save()
                
                self.currentData.removeAllSearchHistory()
                self.update()
            } catch {
                // handle the Core Data error
                Logger.atwyLogs.simpleLog("\(error.localizedDescription)")
            }
        }
    }
    
    public func removeSearch(withUUID uuid: UUID) {
        let backgroundContext = self.controller.container.newBackgroundContext()
        backgroundContext.performAndWait {
            do {
                let request = NSFetchRequest<SearchHistory>(entityName: "SearchHistory")
                
                request.predicate = NSPredicate(format: "uuid == %@", uuid as CVarArg)
                
                let result = try backgroundContext.fetch(request)
                
                result.forEach { backgroundContext.delete($0) }

                try backgroundContext.save()
                
                self.currentData.removeSearch(withUUID: uuid)
                self.update()
            } catch {
                // handle the Core Data error
                Logger.atwyLogs.simpleLog("\(error.localizedDescription)")
            }
        }
    }
    
    public func addToFavorites(video: YTVideo, imageData: Data? = nil) {
        guard !self.currentData.favoriteVideoIds.contains(where: {$0 == video.videoId}), !self.videoIdsAddedToFavorites.contains(video.videoId) else { return }
        self.videoIdsAddedToFavorites.append(video.videoId)
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
                thumbnailData = imageTask.imageData
            }
        
            if let rawThumbnailData = thumbnailData {
                newItem.thumbnailData = self.cropImage(data: rawThumbnailData)
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
            
            self.videoIdsAddedToFavorites.removeAll(where: {$0 == video.videoId})
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
    
    public func addDownloadedVideo(videoId: String, title: String?, description: String?, storageLocation: URL, imageData: Data?, timeLength: String?, timePosted: String?, chapters: [WrappedDownloadedVideoChapter], channelId: String?, channelName: String?, channelThumbnailData: Data?) throws {
        let backgroundContext = PersistenceModel.shared.controller.container.newBackgroundContext()
        try backgroundContext.performAndWait {
            let newVideo = DownloadedVideo(context: backgroundContext)
            newVideo.timestamp = Date()
            newVideo.storageLocation = storageLocation
            newVideo.title = title
            if let imageData = imageData {
                newVideo.thumbnail = self.cropImage(data: imageData)
            }
            newVideo.timeLength = timeLength
            newVideo.timePosted = timePosted
            newVideo.videoId = videoId
            
            for chapter in chapters {
                newVideo.addToChapters(chapter.getEntity(context: backgroundContext))
            }
            
            if let channelId = channelId {
                let fetchRequest = DownloadedChannel.fetchRequest()
                fetchRequest.fetchLimit = 1
                fetchRequest.predicate = NSPredicate(format: "channelId == %@", channelId)
                let result = try? backgroundContext.fetch(fetchRequest)
                
                if let channel = result?.first {
                    channel.thumbnail = channelThumbnailData ?? channel.thumbnail
                    channel.addToVideos(newVideo)
                } else {
                    let newChannel = DownloadedChannel(context: backgroundContext)
                    newChannel.channelId = channelId
                    newChannel.name = channelName
                    newChannel.thumbnail = channelThumbnailData
                    newChannel.addToVideos(newVideo)
                }
            }
            
            newVideo.videoDescription = description
            try backgroundContext.save()
            self.currentData.addDownloadedVideo(videoId: videoId, storageLocation: storageLocation)
            self.update()
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .atwyCoreDataChanged,
                    object: nil
                )
            }
        }
    }
    
    public func addOrUpdateWatchedVideo(videoId: String, watchedUntil: TimeInterval, watchedPercentage: Double) {
        guard PreferencesStorageModel.shared.watchHistoryEnabled else { return }
            
        let backgroundContext = self.controller.container.newBackgroundContext()
        backgroundContext.perform {
            backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            let fetchRequest = WatchedVideo.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "videoId == %@", videoId)
            fetchRequest.fetchLimit = 1
            do {
                let result = try backgroundContext.fetch(fetchRequest)
                if let watchedVideo = result.first {
                    watchedVideo.watchedUntil = watchedUntil
                    watchedVideo.watchedPercentage = watchedPercentage
                    watchedVideo.timestamp = Date()
                } else {
                    let newWatchedVideo = WatchedVideo(context: backgroundContext)
                    newWatchedVideo.videoId = videoId
                    newWatchedVideo.watchedUntil = watchedUntil
                    newWatchedVideo.watchedPercentage = watchedPercentage
                }
                try backgroundContext.save()
                self.currentData.addOrUpdateWatchedVideo(videoId: videoId, watchedUntil: watchedUntil, watchedPercentage: watchedPercentage)
                self.update()
            } catch {
                Logger.atwyLogs.simpleLog("Couldn't add/update watched video: \(error)")
            }
        }
    }
    
    public func removeWatchedVideo(videoId: String) {
        let backgroundContext = self.controller.container.newBackgroundContext()
        backgroundContext.perform {
            let request = WatchedVideo.fetchRequest()
            let predicate = NSPredicate(format: "videoId == %@", videoId)
            request.predicate = predicate
            do {
                let result = try backgroundContext.fetch(request)
                result.forEach { backgroundContext.delete($0) }
                try backgroundContext.save()
                self.currentData.removeWatchedVideo(videoId: videoId)
                self.update()
            } catch {
                Logger.atwyLogs.simpleLog("Couldn't remove watched video: \(error)")
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
            fetchRequest.includesSubentities = true
            fetchRequest.includesPropertyValues = true
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
    
    public func resetLocalWatchHistory() {
        let backgroundContext = self.controller.container.newBackgroundContext()
        backgroundContext.perform {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = WatchedVideo.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            do {
                try backgroundContext.execute(deleteRequest)
            } catch let error as NSError {
                Logger.atwyLogs.simpleLog(" Could not reset local watch history. \(error), \(error.userInfo)" )
            }
        }
    }
    
    struct PersistenceData: Identifiable {
        typealias VideoIdAndLocation = (videoId: String, storageLocation: URL)
        
        typealias WatchedVideoData = (watchedUntil: TimeInterval, watchedPercentage: Double)
        
        private(set) var id = UUID()
        
        private(set) var downloadedVideoIds: [VideoIdAndLocation]
        
        private(set) var favoriteVideoIds: [String]
        
        private(set) var searchHistory: [Search]
        
        private(set) var watchedVideos: Dictionary<String, WatchedVideoData>
        
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
        
        mutating func addSearch(_ search: Search) {
            self.searchHistory.append(search)
            self.searchHistory.sort(by: {$0.timestamp > $1.timestamp})
            self.id = UUID()
        }
        
        mutating func replaceSearchTimestamp(with timestamp: Date, uuid: UUID) {
            guard let index = self.searchHistory.firstIndex(where: { $0.uuid == uuid }) else { return }
            self.searchHistory[index].timestamp = timestamp
            self.searchHistory.sort(by: {$0.timestamp > $1.timestamp})
            self.id = UUID()
        }
        
        mutating func removeAllSearchHistory() {
            self.searchHistory.removeAll()
            self.id = UUID()
        }
        
        mutating func removeSearch(withUUID uuid: UUID) {
            self.searchHistory.removeAll(where: {$0.uuid == uuid})
            self.id = UUID()
        }
        
        func getMatchingHistoryEntries(query: String) -> [Search] {
            return self.searchHistory.filter { $0.matchesQuery(query) }
        }
        
        mutating func addOrUpdateWatchedVideo(videoId: String, watchedUntil: TimeInterval, watchedPercentage: Double) {
            if self.watchedVideos[videoId] != nil {
                self.watchedVideos[videoId]?.watchedUntil = watchedUntil
                self.watchedVideos[videoId]?.watchedPercentage = watchedPercentage
            } else {
                self.watchedVideos[videoId] = (watchedUntil: watchedUntil, watchedPercentage: watchedPercentage)
            }
            self.id = UUID()
        }
        
        mutating func removeWatchedVideo(videoId: String) {
            self.watchedVideos.removeValue(forKey: videoId)
            self.id = UUID()
        }
        
        struct Search: Equatable {
            var query: String
            var timestamp: Date
            var uuid: UUID
            
            func matchesQuery(_ query: String) -> Bool {
                return query == "" || !query.lowercased().components(separatedBy: " ").filter({$0 != ""}).contains(where: {!self.query.lowercased().contains($0)})
            }
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
                attributeSet.keywords?.append(contentsOf: [item.title, item.channel?.name, item.videoDescription].compactMap(\.self))
            } else {
                attributeSet.keywords = [item.title, item.channel?.name, item.videoDescription].compactMap(\.self)
            }
            return attributeSet
        } else if let channel = object as? DownloadedChannel {
            let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
            attributeSet.identifier = channel.channelId
            attributeSet.displayName = channel.name
            attributeSet.thumbnailData = channel.thumbnail
            attributeSet.containerDisplayName = "Channel"
            if attributeSet.keywords != nil {
                attributeSet.keywords?.append(contentsOf: [channel.name].compactMap(\.self))
            } else {
                attributeSet.keywords = [channel.name].compactMap(\.self)
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
                attributeSet.keywords?.append(contentsOf: [favorite.title, favorite.channel?.name].compactMap(\.self))
            } else {
                attributeSet.keywords = [favorite.title, favorite.channel?.name].compactMap(\.self)
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
                attributeSet.keywords?.append(contentsOf: [chapter.title].compactMap(\.self))
            } else {
                attributeSet.keywords = [chapter.title].compactMap(\.self)
            }
            return attributeSet
        }
        return nil
    }
}
