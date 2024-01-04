//
//  HistoryView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 03.01.2024.
//

import SwiftUI
import YouTubeKit

struct HistoryView: View {
    @State private var shouldReloadScrollView: Bool = false
    @StateObject private var model = Model()
    @ObservedObject private var PSM = PreferencesStorageModel.shared
    var body: some View {
        VStack {
            if model.isFetching {
                LoadingView()
                    .centered()
            } else if let historyResponse = model.historyResponse {
                GeometryReader { geometry in
                    ScrollView {
                        ForEach(Array(historyResponse.videosAndTime.enumerated()), id: \.offset) { _, videoGroup in
                            VideoGroupView(videoSize: CGSize(width: geometry.size.width, height: (PSM.propetriesState[.videoViewMode] as? PreferencesStorageModel.Properties.VideoViewModes) == .halfThumbnail ? 180 : geometry.size.width * 9/16 + 90), videoGroup: videoGroup)
                        }
                    }
                }
            } else if let error = model.error {
                Text("Error: " + error)
            } else {
                Color.clear.frame(width: 0, height: 0)
                    .onAppear {
                        model.fetchHistory()
                    }
            }
        }
        .navigationTitle(model.historyResponse?.title ?? "History")
    }
    
    struct VideoGroupView: View {
        @Environment(\.colorScheme) private var colorScheme

        let videoSize: CGSize
        let videoGroup: (groupTitle: String, videosArray: [(YTVideo, suppressToken: String?)])
        @State private var isExpanded: Bool = true
        var body: some View {
            VStack {
                HStack {
                    Text(videoGroup.groupTitle)
                        .font(.largeTitle)
                        .foregroundStyle(colorScheme.textColor)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 15, height: 15)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                        .onTapGesture {
                            withAnimation(.spring, {
                                isExpanded.toggle()
                            })
                        }
                        .foregroundStyle(colorScheme.textColor)
                }
                .padding([.horizontal, .top])
                .zIndex(1)
                
                VStack {
                    ForEach(Array(videoGroup.videosArray.map({$0.0}).enumerated()), id: \.offset) { _, video in
                        VideoFromSearchView(video: video)
                            .frame(width: videoSize.width, height: videoSize.height, alignment: .center)
                    }
                }
                .opacity(isExpanded ? 1 : 0)
                .frame(height: isExpanded ? nil : 0)
                .clipped()
                
                //                        ElementsInfiniteScrollView(items: model.getBindingFromGroup(videoGroup), shouldReloadScrollView: $shouldReloadScrollView)
            }
        }
    }
    
    class Model: ObservableObject {
        @Published var historyResponse: HistoryResponse?
        @Published var error: String?
        @Published var isFetching: Bool = false
        
        func fetchHistory() {
            DispatchQueue.main.async {
                self.isFetching = true
                self.historyResponse = nil
                self.error = nil
            }
            HistoryResponse.sendRequest(youtubeModel: YTM, data: [:], result: { response, error in
                if let response = response {
                    DispatchQueue.main.async {
                        self.historyResponse = response
                        self.isFetching = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.error = error?.localizedDescription ?? "No error."
                        self.isFetching = false
                    }
                }
            })
        }
        
        func getBindingFromGroup(_ group: (groupTitle: String, videosArray: [(YTVideo, suppressToken: String?)])) -> Binding<[any YTSearchResult]> {
            return Binding(get: {
                return group.videosArray.map({$0.0})
            }, set: { _ in
                return
            })
        }
    }
}
