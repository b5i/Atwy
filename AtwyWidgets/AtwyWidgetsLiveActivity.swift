//
//  AtwyWidgetsLiveActivity.swift
//  AtwyWidgets
//
//  Created by Antoine Bollengier on 14.03.2024.
//  Copyright © 2024 Antoine Bollengier. All rights reserved.
//  

import ActivityKit
import WidgetKit
import SwiftUI

struct DownloadingsProgressAttributes: ActivityAttributes {
    typealias ContentState = DownloadingsState
    
    struct DownloadingsState: Codable & Hashable {
        let downloadingsCount: Int
        let globalProgress: CGFloat
    }
}

@available(iOS 16.1, *)
struct DownloadingsProgressLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DownloadingsProgressAttributes.self) { context in
            // Lock screen/banner UI goes here
            HStack {
                let count = context.state.downloadingsCount
                Text("\(count) video\(count > 1 ? "s" : "") remaining")
                Spacer()
                CircularProgressView(progress: context.state.globalProgress)
                    .frame(width: 30, height: 30)
                    .overlay(alignment: .center, content: {
                        Text("\(Int((100 * context.state.globalProgress).rounded(.down)))%")
                            .font(.system(size: 10))
                    })
            }
            .padding()
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("\(context.state.downloadingsCount) videos")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("remaining")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    CircularProgressView(progress: context.state.globalProgress, lineWidth: 10)
                        .frame(width: 80, height: 80)
                        .overlay(alignment: .center, content: {
                            Text("\(Int((100 * context.state.globalProgress).rounded(.down)))%")
                                .font(.system(size: 25))
                        })
                }
            } compactLeading: {
                Text("\(Int((100 * context.state.globalProgress).rounded(.down)))%")
                    .padding(.leading, 5)
            } compactTrailing: {
                CircularProgressView(progress: context.state.globalProgress)
                    .frame(width: 20, height: 20)
                    .overlay(alignment: .center, content: {
                        Text(String(context.state.downloadingsCount))
                            .font(.system(size: 10))
                    })
                    .padding(.leading)
            } minimal: {
                CircularProgressView(progress: context.state.globalProgress)
                    .frame(width: 20, height: 20)
                    .overlay(alignment: .center, content: {
                        Text(String(context.state.downloadingsCount))
                            .font(.system(size: 10))
                    })
            }
            //.widgetURL(URL(string: "http://www.apple.com"))// to replace with a custom one for atwy
            //.keylineTint(Color.red)
        }
    }
}
