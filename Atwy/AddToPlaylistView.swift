//
//  AddToPlaylistView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 10.02.23.
//

import SwiftUI
import YouTubeKit

struct AddToPlaylistView: View {
    @Environment(\.dismiss) private var dismiss
    let video: YTVideo
    @State private var search: String = ""
    @State private var showNewPlaylistForm: Bool = false
    @State private var newPlaylistName: String = ""
    @State private var selectedPrivacy: Int = 0
    @StateObject private var model = Model()
    var body: some View {
        NavigationStack {
            VStack {
                if model.isFetching {
                    LoadingView()
                } else {
                    if let availablePlaylists = model.response {
                        ScrollView(.vertical, content: {
                            if showNewPlaylistForm {
                                PlaylistCreationView(showNewPlaylistForm: $showNewPlaylistForm, model: model)
                            } else {
                                Button {
                                    // Show little add menu
                                    withAnimation {
                                        showNewPlaylistForm = true
                                    }
                                } label: {
                                    Image(systemName: "plus")
                                        .foregroundColor(.green)
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                }
                            }
                            ForEach(Array(availablePlaylists.playlistsAndStatus.filter({(search.isEmpty) ? true : $0.0.title?.contains(search) ?? false}).enumerated()), id: \.offset) { row in
                                getPlaylistRowView(playlist: row.element.playlist, isVideoContained: row.element.isVideoPresentInside)
                            }
                        })
                        .searchable(text: $search)
                        .padding(.top)
                    } else {
                        Text("No playlist available.")
                    }
                }
            }
            .onAppear {
                if model.response == nil, model.isFetching != true {
                    model.getAvailablePlaylists(video: video)
                }
            }
            .navigationTitle("Add to playlist")
            #if os(macOS)
            .toolbar(content: {
                ToolbarItem(placement: .secondaryAction, content: {
                    Button {
                        dismiss()
                    } label: {
                        Text("OK")
                    }
                })
            })
            #else
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing, content: {
                    Button {
                        dismiss()
                    } label: {
                        Text("OK")
                    }
                })
            })
            #endif
        }
    }
    
    @ViewBuilder private func getPlaylistRowView(playlist: YTPlaylist, isVideoContained: Bool) -> some View {
        HStack {
            Text(playlist.title ?? "")
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let privacy = playlist.privacy {
                PrivacyIconView(privacy: privacy)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            let isFetchingForPlaylist = model.isModifyingPlaylistWithId.contains(playlist.playlistId)
            if isVideoContained {
                Button {
                    model.removeVideoFromPlaylist(playlist)
                } label: {
                    if isFetchingForPlaylist {
                        ProgressView()
                    } else {
                        Image(systemName: "checkmark.square")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                }
                .disabled(isFetchingForPlaylist)
                .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                Button {
                    model.addVideoToPlaylist(playlist)
                } label: {
                    if isFetchingForPlaylist {
                        ProgressView()
                    } else {
                        Image(systemName: "square")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                }
                .disabled(isFetchingForPlaylist)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding()
        .padding(.horizontal)
        Divider()
    }
    
    public struct PlaylistCreationView: View {
        @Binding var showNewPlaylistForm: Bool
        @State private var newPlaylistName: String = ""
        @State private var selectedPrivacy: Int = 0
        @ObservedObject var model: Model
        var body: some View {
            VStack {
                Button {
                    // Hide little add menu
                    withAnimation {
                        showNewPlaylistForm = false
                    }
                } label: {
                    Image(systemName: "multiply")
                        .foregroundColor(.red)
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                }
                Form {
                    TextField("Playlist Name", text: $newPlaylistName)
                }
                .frame(height: 100, alignment: .center)
                Picker("", selection: $selectedPrivacy, content: {
                    Text("Private").tag(0)
                    Text("Unlisted").tag(1)
                    Text("Public").tag(2)
                })
                .pickerStyle(.menu)
                if model.isCreatingPlaylist {
                    ProgressView()
                } else {
                    Button {
                        let privacy: YTPrivacy
                        switch selectedPrivacy {
                        case 0:
                            privacy = .private
                        case 1:
                            privacy = .unlisted
                        case 2:
                            privacy = .public
                        default:
                            privacy = .private
                        }
                        model.createPlaylistWithVideoInside(title: newPlaylistName, privacy: privacy, end: { result in
                            if result {
                                DispatchQueue.main.async {
                                    withAnimation {
                                        showNewPlaylistForm = false
                                    }
                                }
                            }
                        })
                    } label: {
                        Text("Create")
                    }
                    .buttonStyle(.bordered)
                }
                Divider()
            }
        }
    }
    
    public class Model: ObservableObject {
        @Published public var response: AllPossibleHostPlaylistsResponse?
        /// Array of playlistIds.
        @Published public var isModifyingPlaylistWithId: Set<String> = Set()
        @Published public var isFetching: Bool = false
        @Published public var isCreatingPlaylist: Bool = false
        @Published public var hasError: Bool = false
        @Published public var video: YTVideo?
        
        public func getAvailablePlaylists(video: YTVideo) {
            DispatchQueue.main.async {
                self.video = video
                self.response = nil
                self.hasError = false
                self.isFetching = true
            }
            video.fetchAllPossibleHostPlaylists(youtubeModel: YTM, result: { result in
                switch result {
                case .success(let response):
                    DispatchQueue.main.async {
                        self.isFetching = false
                        self.hasError = false
                        self.response = response
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.isFetching = false
                        self.hasError = true
                    }
                    print("Could not fetch playlists, error: \(String(describing: error)).")
                }
            })
        }
        
        public func createPlaylistWithVideoInside(title: String, privacy: YTPrivacy, end: ((Bool) -> Void)? = nil) {
            if self.response != nil, let video = self.video {
                DispatchQueue.main.async {
                    self.isCreatingPlaylist = true
                }
                CreatePlaylistResponse.sendRequest(youtubeModel: YTM, data: [.query: title, .params: privacy.rawValue, .movingVideoId: video.videoId], result: { result in
                    switch result {
                    case .success(let response):
                        if let newPlaylistId = response.createdPlaylistId {
                            DispatchQueue.main.async {
                                self.response?.playlistsAndStatus.insert((YTPlaylist(playlistId: newPlaylistId, title: title, privacy: privacy), true), at: 0)
                                end?(true)
                            }
                        } else {
                            end?(true)
                        }
                    case .failure(let error):
                        print("Couldn't create playlist, error: \(String(describing: error)).")
                        end?(true)
                    }
                    DispatchQueue.main.async {
                        self.isCreatingPlaylist = false
                    }
                })
            }
        }
        
        public func addVideoToPlaylist(_ playlist: YTPlaylist) {
            if self.response != nil, let video = self.video {
                DispatchQueue.main.async {
                    self.isModifyingPlaylistWithId.insert(playlist.playlistId)
                }
                AddVideoToPlaylistResponse.sendRequest(youtubeModel: YTM, data: [.movingVideoId: video.videoId, .browseId: playlist.playlistId], result: { result in
                    switch result {
                    case .success(let response):
                        if response.success, let playlistIndexToModify = self.response?.playlistsAndStatus.firstIndex(where: {$0.playlist.playlistId == playlist.playlistId}) {
                            DispatchQueue.main.async {
                                self.response?.playlistsAndStatus[playlistIndexToModify].isVideoPresentInside = true
                            }
                        }
                    case .failure(let error):
                        print("Couldn't add video to playlist, error: \(String(describing: error)).")
                    }
                    DispatchQueue.main.async {
                        self.isModifyingPlaylistWithId.remove(playlist.playlistId)
                    }
                })
            }
        }
        
        public func removeVideoFromPlaylist(_ playlist: YTPlaylist) {
            if self.response != nil, let video = self.video {
                DispatchQueue.main.async {
                    self.isModifyingPlaylistWithId.insert(playlist.playlistId)
                }
                RemoveVideoByIdFromPlaylistResponse.sendRequest(youtubeModel: YTM, data: [.movingVideoId: video.videoId, .browseId: playlist.playlistId], result: { result in
                    switch result {
                    case .success(let response):
                        if response.success, let playlistIndexToModify = self.response?.playlistsAndStatus.firstIndex(where: {$0.playlist.playlistId == playlist.playlistId}) {
                            DispatchQueue.main.async {
                                self.response?.playlistsAndStatus[playlistIndexToModify].isVideoPresentInside = false
                            }
                        }
                    case .failure(let error):
                        print("Couldn't add video to playlist, error: \(String(describing: error)).")
                    }
                    DispatchQueue.main.async {
                        self.isModifyingPlaylistWithId.remove(playlist.playlistId)
                    }
                })
            }
        }
    }
}
