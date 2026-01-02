//
//  AtwyWidgetsLiveActivity.swift
//  AtwyWidgets
//
//  Created by Antoine Bollengier on 14.03.2024.
//  Copyright © 2024-2026 Antoine Bollengier. All rights reserved.
//  

import ActivityKit
import WidgetKit
import SwiftUI

struct DownloaderProgressAttributes: ActivityAttributes {
    typealias ContentState = DownloaderState
        
    struct DownloaderState: Codable & Hashable {
        let title: String
        let channelName: String
        let progress: CGFloat?
        
        init(title: String, channelName: String, progress: CGFloat?) {
            self.title = title
            self.channelName = channelName
            self.progress = progress
        }
    }
}

@available(iOS 16.1, *)
struct DownloaderProgressLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DownloaderProgressAttributes.self) { context in
            // Lock screen/banner UI goes here
            HStack {
                /*
                if let data = context.attributes.thumbnailData, let image = UIImage(data: data) {
                    //CachedAsyncImage(url: thumbnailURL)
                    Image(uiImage: image)
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                }
                 */
                VStack(alignment: .leading) {
                    Text(context.state.title)
                    Text(context.state.channelName)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                Spacer()
                if let progress = context.state.progress {
                    CircularProgressView(progress: progress)
                        .frame(width: 30, height: 30)
                        .overlay(alignment: .center, content: {
                            Text("\(Int((100 * progress).rounded(.down)))%")
                                .font(.system(size: 10))
                        })
                }
            }
            .padding()
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    if let progress = context.state.progress {
                        Text("\(Int((100 * progress).rounded(.down)))%")
                            .font(.system(size: 25))
                            .centered()
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading) {
                        Text(context.state.title)
                        Text(context.state.channelName)
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let progress = context.state.progress {
                        CircularProgressView(progress: progress, lineWidth: 10)
                            .frame(width: 80, height: 80)
                            .padding()
                    }
                }
            } compactLeading: {
                /*
                if let data = context.attributes.thumbnailData, let image = UIImage(data: data) {
                    //CachedAsyncImage(url: thumbnailURL)
                    Image(uiImage: image)
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                } else */if let progress = context.state.progress {
                    Text("\(Int((100 * progress).rounded(.down)))%")
                        .padding(.leading, 5)
                }
            } compactTrailing: {
                if let progress = context.state.progress {
                    CircularProgressView(progress: progress)
                        .frame(width: 20, height: 20)
                        .padding(.leading)
                }
            } minimal: {
                if let progress = context.state.progress {
                    CircularProgressView(progress: progress)
                        .frame(width: 20, height: 20)
                }
            }
            //.widgetURL(URL(string: "http://www.apple.com"))// to replace with a custom one for atwy
            //.keylineTint(Color.red)
        }
    }
}

@available(iOS 16.2, *)
struct LiveActivitiesPreviewProvider: PreviewProvider {
    static let activityAttributes = DownloaderProgressAttributes()
    
    static let state = DownloaderProgressAttributes.ContentState(title: "This is a test video", channelName: "YouTuber", progress: 0.7)
    
    static var previews: some View {
        activityAttributes
            .previewContext(state, viewKind: .dynamicIsland(.compact))
            .previewDisplayName("Compact")
        
        activityAttributes
            .previewContext(state, viewKind: .dynamicIsland(.expanded))
            .previewDisplayName("Expanded")
        
        activityAttributes
            .previewContext(state, viewKind: .content)
            .previewDisplayName("Notification")
        
        activityAttributes
            .previewContext(state, viewKind: .dynamicIsland(.minimal))
            .previewDisplayName("Minimal")
        
    }
}
