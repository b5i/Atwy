//
//  SharePlayCoordinationManager.swift
//  Atwy
//
//  Created by Antoine Bollengier on 19.03.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation
import GroupActivities
import YouTubeKit
import Combine

struct WatchInGroupActivity: GroupActivity {
    static var activityIdentifier = "Antoine-Bollengier.Atwy.shareplay"
    var metadata: GroupActivityMetadata {
        var metadata = GroupActivityMetadata()
        metadata.type = .watchTogether
        metadata.title = video.title
        return metadata
    }

    var video: YTVideo
}

struct WatchInGroupActivityMetadata: Codable, Equatable {
    var videoId: String
    var title: String
    var owner: String
    var description: String
    var thumbnailURL: [String]?
}

class CoordinationManager {
    static let shared = CoordinationManager()

    private var subscriptions = Set<AnyCancellable>()

    // Published values that the player, and other UI items, observe.
    @Published var enqueuedVideo: YTVideo?
    @Published var groupSession: GroupSession<WatchInGroupActivity>?

    private init() {
        Task {
            // Await new sessions to watch movies together.
            for await groupSession in WatchInGroupActivity.sessions() {
                print("Got a group session")
                // Set the app's active group session.
                self.groupSession = groupSession

                // Remove previous subscriptions.
                subscriptions.removeAll()

                // Observe changes to the session state.
                groupSession.$state.sink { [weak self] state in
                    if case .invalidated = state {
                        // Set the groupSession to nil to publish
                        // the invalidated session state.
                        self?.groupSession = nil
                        self?.subscriptions.removeAll()
                    }
                }.store(in: &subscriptions)

                // Join the session to participate in playback coordination.
                groupSession.join()

                // Observe when the local user or a remote participant starts an activity.
                groupSession.$activity.sink { [weak self] activity in
                    // Set the movie to enqueue it in the player.
                    self?.enqueuedVideo = activity.video
                }.store(in: &subscriptions)
            }
        }
    }

    // Prepares the app to play the movie.
    func prepareToPlay(_ selectedVideo: YTVideo) {
        // Return early if the app enqueues the movie.
        guard enqueuedVideo != selectedVideo else { return }

        if let groupSession = groupSession {
            // If there's an active session, create an activity for the new selection.
            if groupSession.activity.video != selectedVideo {
                groupSession.activity = WatchInGroupActivity(video: selectedVideo)
            }
        } else {

            Task {
                // Create a new activity for the selected movie.
                let activity = WatchInGroupActivity(video: selectedVideo)

                // Await the result of the preparation call.
                switch await activity.prepareForActivation() {

                case .activationDisabled:
                    // Playback coordination isn't active, or the user prefers to play the
                    // movie apart from the group. Enqueue the movie for local playback only.
                    self.enqueuedVideo = selectedVideo

                case .activationPreferred:
                    // The user prefers to share this activity with the group.
                    // The app enqueues the movie for playback when the activity starts.
                    do {
                        _ = try await activity.activate()
                    } catch {
                        print("Unable to activate the activity: \(error)")
                    }

                case .cancelled:
                    // The user cancels the operation. Do nothing.
                    break

                default: ()
                }
            }
        }
    }
}
