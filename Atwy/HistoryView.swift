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
                        LazyVStack {
                            ForEach(historyResponse.results, id: \.id) { historyPart in
                                VideoGroupView(model: model, videoSize: CGSize(width: geometry.size.width, height: PSM.videoViewMode == .halfThumbnail ? 180 : geometry.size.width * 9/16 + 90), historyPart: historyPart)
                            }
                            if self.model.historyResponse?.continuationToken != nil {
                                Color.clear.frame(width: 0, height: 0)
                                    .onAppear {
                                        self.model.fetchContinuation()
                                    }
                            }
                        }
                    }
                    .listStyle(.plain)
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
        
        @ObservedObject var model: Model
        
        let videoSize: CGSize
        let historyPart: HistoryResponse.HistoryBlock
        @State private var isExpanded: Bool = true
        var body: some View {
            VStack {
                HStack {
                    Text(historyPart.groupTitle)
                        .font(.largeTitle)
                        .foregroundStyle(colorScheme.textColor)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 15, height: 15)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                        .animation(.smooth, value: isExpanded)
                        .foregroundStyle(colorScheme.textColor)
                }
                .padding()
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring, {
                        isExpanded.toggle()
                    })
                }
                .frame(height: 50, alignment: .top)
                .background(colorScheme.backgroundColor)
                .zIndex(1)
                .animation(nil, value: isExpanded)
                Spacer()
                
                
                ForEach(Array(self.model.makeVideoArray(forGroup: self.historyPart).enumerated()), id: \.offset) { _, video in
                    VideoFromSearchView(videoWithData: video)
                        .frame(width: videoSize.width, height: videoSize.height, alignment: .center)
                }
                .opacity(isExpanded ? 1 : 0)
                .frame(height: isExpanded ? nil : 0)
                .disabled(!isExpanded)
                //                        ElementsInfiniteScrollView(items: model.getBindingFromGroup(videoGroup), shouldReloadScrollView: $shouldReloadScrollView)
            }
            .clipped()
        }
    }
    
    class Model: ObservableObject {
        @Published var historyResponse: HistoryResponse?
        @Published var error: String?
        @Published var isFetching: Bool = false
        
        private var isFetchingContinuation: Bool = false
        
        func fetchHistory() {
            DispatchQueue.main.async {
                self.isFetching = true
                self.historyResponse = nil
                self.error = nil
            }
            HistoryResponse.sendNonThrowingRequest(youtubeModel: YTM, data: [:], result: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let response):
                    DispatchQueue.main.async {
                        self.historyResponse = response
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.error = error.localizedDescription
                    }
                }
                DispatchQueue.main.async {
                    self.isFetching = false
                }
            })
        }
        
        func fetchContinuation() {
            guard !self.isFetchingContinuation, let historyResponse = self.historyResponse, historyResponse.continuationToken != nil else { return }
            DispatchQueue.main.async {
                self.error = nil
            }
            self.isFetchingContinuation = true
            
            historyResponse.fetchContinuation(youtubeModel: YTM, result: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let continuation):
                    DispatchQueue.main.async {
                        self.historyResponse?.mergeContinuation(continuation)
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.error = error.localizedDescription
                    }
                }
                DispatchQueue.main.async {
                    self.isFetchingContinuation = false
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
        
        func makeVideoArray(forGroup group: HistoryResponse.HistoryBlock) -> [YTVideoWithData] {
            return group.contentsArray
                .compactMap { $0 as? HistoryResponse.HistoryBlock.VideoWithToken }
                .map { (videoWithToken: HistoryResponse.HistoryBlock.VideoWithToken) in
                    var videoData = YTElementDataSet()
                    if let suppressToken = videoWithToken.suppressToken {
                        videoData.removeFromPlaylistAvailable = {
                            self.historyResponse?.removeVideo(withSuppressToken: suppressToken, youtubeModel: YTM, result: { error in
                                guard error == nil else { return }
                                var subBlockIndex: Int? = nil
                                guard let blockIndex = self.historyResponse?.results.firstIndex(where: { block in
                                    for (offset, subBlock) in Array(block.contentsArray.enumerated()) {
                                        if let subBlock = subBlock as? HistoryResponse.HistoryBlock.VideoWithToken {
                                            if subBlock.suppressToken == suppressToken {
                                                subBlockIndex = offset
                                                return true
                                            }
                                        }
                                    }
                                    return false
                                }), let subBlockIndex = subBlockIndex else { return }
                                DispatchQueue.main.async {
                                    withAnimation {
                                        self.historyResponse?.results[blockIndex].contentsArray.remove(at: subBlockIndex)
                                        if ((self.historyResponse?.results[blockIndex].contentsArray.isEmpty) == true) {
                                            self.historyResponse?.results.remove(at: blockIndex)
                                        }
                                    }
                                }
                            })
                        }
                    }
                    
                    return videoWithToken.video.withData(videoData)
                }
        }
    }
}
