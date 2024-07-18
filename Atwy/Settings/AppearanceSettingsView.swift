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
    @State private var videoViewChoice: VideoViewModes = PreferencesStorageModel.shared.videoViewMode
    
    var body: some View {
        SettingsMenu(title: "Appearance") { _ in
            SettingsSection(title: "Videos Display Mode") {
                Setting(textDescription: nil, action: SACustomAction(title: "", actionView: {
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
                    .frame(height: 400)
                    .onAppear {
                        self.videoViewChoice = PreferencesStorageModel.shared.videoViewMode
                    }
                }))
            }
        }
    }
}

#Preview {
    AppearanceSettingsView()
}
