//
//  DeleteFromFavoritesView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 23.01.23.
//

import SwiftUI
import CoreData
import YouTubeKit

struct DeleteFromFavoritesView: View {
    var context = PersistenceModel.shared.context
    @State var video: YTVideo
    var body: some View {
        Button(role: .destructive) {
            deleteFromFavorites()
        } label: {
            HStack {
                Text("Remove Favorite")
                Image(systemName: "trash")
            }
            .tint(.red)
        }
    }

    private func deleteFromFavorites() {
        let fetchRequest = FavoriteVideo.fetchRequest()
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "videoId == %@", video.videoId)
        do {
            let fetchResult = try PersistenceModel.shared.context.fetch(fetchRequest)
            if fetchResult.count == 1 {
                let newObject = fetchResult.first!
                if let channel = newObject.channel, channel.videosArray.count == 0, channel.favoritesArray.count == 1 {
                    context.delete(channel)
                }
                context.delete(newObject)
                do {
                    try context.save()

                    NotificationCenter.default.post(
                        name: Notification.Name("CoreDataChanged"),
                        object: nil
                    )

                } catch {
                    // handle the Core Data error
                    print(error)
                }
            } else {
                print("no item found")
            }
        } catch {
            print("can't modify to context")
            print(error)
        }
    }
}
