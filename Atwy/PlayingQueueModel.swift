//
//  PlayingQueueModel.swift
//  Atwy
//
//  Created by Antoine Bollengier on 28.01.23.
//

import Foundation
import YouTubeKit

class PlayingQueueModel: ObservableObject {

    static let shared = PlayingQueueModel()

    @Published var queue: [YTVideo] = [] {
        didSet {
            if (VideoPlayerModel.shared.video == nil) && !VideoPlayerModel.shared.isLoadingVideo && queue != oldValue {
                loadNextVideo()
            }
        }
    }

    init () {
        NotificationCenter.default.addObserver(forName: .atwyAVPlayerEnded, object: nil, queue: nil, using: { _ in
            if !self.queue.isEmpty {
                self.loadNextVideo()
            }
        })
    }

    private func loadNextVideo() {
        if let video = queue.first {
            VideoPlayerModel.shared.loadVideo(video: video)
            self.queue.removeFirst()
            VideoPlayerModel.shared.player.play()
        }
        self.indexQueue()
    }

    func indexQueue() {
        var index = 0
        self.queue = self.queue.map({ item in
            var newItem = item
            newItem.id = index
            index += 1
            if !self.queue.contains(where: {$0.videoId == item.videoId}) {
                VideoThumbnailsManager.main.images.removeValue(forKey: item.videoId)
            }
            return newItem
        })
    }

    func loadVideoWithID(_ id: Int) {
        if self.queue.count > id {
            VideoPlayerModel.shared.loadVideo(video: self.queue[id])
            var newQueue = queue
            newQueue = newQueue.filter({ video in
                if (video.id ?? 0) <= id {
                    return false
                } else {
                    return true
                }
            })
            self.queue = newQueue
            self.indexQueue()
            VideoPlayerModel.shared.player.play()
        }
    }
}
