//
//  AppearanceSettingsView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 08.10.2023.
//

import SwiftUI
import YouTubeKit

struct AppearanceSettingsView: View {
    typealias VideoViewModes = PreferencesStorageModel.Properties.VideoViewModes
    
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var PSM = PreferencesStorageModel.shared
    @ObservedObject private var APIM = APIKeyModel.shared
    @State private var videoViewChoice: VideoViewModes
    
    init() {
        /// Maybe using AppStorage would be better
        if let state = PreferencesStorageModel.shared.propetriesState[.videoViewMode] as? VideoViewModes {
            self._videoViewChoice = State(wrappedValue: state)
        } else {
            let defaultViewMode: VideoViewModes = PreferencesStorageModel.Properties.videoViewMode.getDefaultValue() as? VideoViewModes ?? .fullThumbnail
            self._videoViewChoice = State(wrappedValue: defaultViewMode)
        }
    }
    var body: some View {
        GeometryReader { geometry in
            VStack {
                List {
                    Section("Videos display mode", content: {
                        GeometryReader { sectionGeometry in
                            VStack {
                                //                                    let videoThumbnailData = ImageRenderer(content: Rectangle().foregroundStyle(.gray)).uiImage?.pngData()
                                let videoThumbnailData = Data()
                                let video = YTVideo(videoId: "", title: "My video!", channel: .init(channelId: "", name: "Unknown YouTuber"))
                                HStack {
                                    VideoView(videoWithData: video.withData(.init(allowChannelLinking: false, thumbnailData: videoThumbnailData)))
                                        .frame(width: sectionGeometry.size.width, height: 180)
                                        .scaleEffect(0.85)
                                        .frame(width: sectionGeometry.size.width * 0.85, height: 153)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    Image(systemName: videoViewChoice == .fullThumbnail ? "circle" : "checkmark.circle.fill")
                                        .foregroundStyle(videoViewChoice == .fullThumbnail ? colorScheme.textColor : .blue)
                                        .onTapGesture {
                                            videoViewChoice = .halfThumbnail
                                            PSM.setNewValueForKey(.videoViewMode, value: videoViewChoice)
                                        }
                                }
                                HStack {
                                    let ownerImageData = ImageRenderer(content: UserPreferenceCircleView()).uiImage?.pngData()
                                    VideoView2(videoWithData: video.withData(.init(allowChannelLinking: false, channelAvatarData: ownerImageData, thumbnailData: videoThumbnailData)))
                                    //                                            .frame(width: sectionGeometry.size.width, height: sectionGeometry.size.width * 9/16 + 90)
                                        .scaleEffect(0.85)
                                        .frame(width: sectionGeometry.size.width * 0.85, height: (sectionGeometry.size.width * 9/16 + 90) * 0.85)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    Image(systemName: videoViewChoice == .halfThumbnail ? "circle" : "checkmark.circle.fill")
                                        .foregroundStyle(videoViewChoice == .halfThumbnail ? colorScheme.textColor : .blue)
                                        .onTapGesture {
                                            videoViewChoice = .fullThumbnail
                                            PSM.setNewValueForKey(.videoViewMode, value: videoViewChoice)
                                        }
                                }
                            }
                        }
                        .frame(width: geometry.size.width * 0.9, height: geometry.size.height * 0.75)
                    })
                    .onAppear {
                        if let state = PreferencesStorageModel.shared.propetriesState[.videoViewMode] as? PreferencesStorageModel.Properties.VideoViewModes {
                            self.videoViewChoice = state
                        } else {
                            self.videoViewChoice = PreferencesStorageModel.Properties.videoViewMode.getDefaultValue() as? VideoViewModes ?? .fullThumbnail
                        }
                    }
                }
            }
        }
        .navigationTitle("Appearance")
    }
}
