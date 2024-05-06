//
//  SearchView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 24.11.22.
//

import SwiftUI
import InfiniteScrollViews
import YouTubeKit
import SwipeActions

let YTM = YouTubeModel()

struct SearchView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismissSearch) private var dismissSearch
    @State private var autoCompletion: [String] = []
    @State private var search: String = "" {
        didSet {
            print("Refreshing")
            refreshAutoCompletionEntries()
        }
    }
    @State private var autoCompletionHeaders: HeadersList?
    @State private var needToReload = true
    @State private var isShowingSettingsSheet: Bool = false
    
    @State private var firstDisplayedResult: Int = 0
    @State private var shouldReloadScrollView: Bool = false
    @State private var hasToReloadPadding: Bool = true
    @State private var isShowingPaddedFirstVideo: Bool = false
    
    @ObservedObject private var model = Model.shared
    @ObservedObject private var IUTM = IsUserTypingModel.shared
    @ObservedObject private var VPM = VideoPlayerModel.shared
    @ObservedObject private var NPM = NavigationPathModel.shared
    @ObservedObject private var APIM = APIKeyModel.shared
    @ObservedObject private var NRM = NetworkReachabilityModel.shared
    @ObservedObject private var PSM = PreferencesStorageModel.shared
    var body: some View {
        NavigationStack(path: $NPM.searchTabPath) {
            VStack {
                if IUTM.userTyping {
                    if !autoCompletion.isEmpty {
                        ZStack {
                            RoundedRectangle(cornerRadius: 15)
                                .foregroundColor(.gray)
                                .opacity(0.2)
                            ScrollView {
                                LazyVStack {
                                    ForEach(autoCompletion, id: \.self) { completion in
                                        Button {
                                            search = completion
                                            model.getVideos(completion)
#if !os(macOS)
                                            //Close keyboard
                                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
#endif
                                        } label: {
                                            Text(completion)
                                                .foregroundColor(colorScheme.textColor)
                                        }
                                        Divider()
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: 400, maxHeight: 150, alignment: .center)
                    }
                }
                VStack {
                    if model.isFetching {
                        LoadingView()
                    } else if let error = model.error {
                        VStack (alignment: .center) {
                            Spacer()
                            Image(systemName: "multiply.circle")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.red)
                            Text(error)
                                .foregroundColor(.red)
                            Button {
                                search = ""
                                dismissSearch()
                                model.getVideos()
                            } label: {
                                Text("Go home")
                            }
                            .buttonStyle(.bordered)
                            Spacer()
                        }
                    } else if model.items.isEmpty && model.error == nil {
                        GeometryReader { geometry in
                            ScrollView {
                                VStack {
                                    Text("No videos found...")
                                        .foregroundColor(colorScheme.textColor)
                                    Text("Search videos or pull up to refresh for the algorithm to fill this menu.")
                                        .foregroundStyle(.gray)
                                        .font(.caption)
                                }
                                .frame(width: geometry.size.width, height: geometry.size.height)
                            }
                            .scrollIndicators(.hidden)
                            .refreshable(action: {
                                if search.isEmpty {
                                    model.getVideos()
                                } else {
                                    model.getVideos(search)
                                }
                            })
                        }
                    } else {
                        let itemsBinding = Binding(get: {
                            return model.items.map({YTElementWithData(element: $0, data: .init())})
                        }, set: { newValue in
                            model.items = newValue.map({$0.element})
                        })
                        ElementsInfiniteScrollView(
                            items: itemsBinding,
                            shouldReloadScrollView: $shouldReloadScrollView, 
                            refreshAction: { endAction in
                                withAnimation(.easeOut(duration: 0.3)) {
                                    endAction()
                                    if search.isEmpty {
                                        model.getVideos()
                                    } else {
                                        model.getVideos(search)
                                    }
                                }
                            },
                            fetchMoreResultsAction: {
                                if !model.isFetchingContination {
                                    model.getVideosContinuation({
                                        self.shouldReloadScrollView = true
                                    })
                                }
                            }
                        )
                    }
                }
            }
            .routeContainer()
#if os(macOS)
            .searchable(text: $search, placement: .toolbar)
#else
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always))
#endif
            .autocorrectionDisabled(true)
            .onChange(of: search) { newValue in
                IUTM.isMainSearchTextEmpty = newValue.isEmpty
                refreshAutoCompletionEntries()
            }
            .onSubmit(of: .search, {
                model.getVideos(search)
            })
            .onAppear {
                if needToReload {
                    if search.isEmpty {
                        model.getVideos()
                    } else {
                        model.getVideos(search)
                    }
                    needToReload = false
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.automatic)
            .customNavigationTitleWithRightIcon {
                ShowSettingsButtonView()
            }
        }
    }
    
    class Model: ObservableObject {
        static public let shared = Model()
        
        @Published var items: [any YTSearchResult] = []
        @Published var isFetching: Bool = false
        @Published var isFetchingContination: Bool = false
        @Published var error: String?
        
        private var homeResponse: HomeScreenResponse?
        private var searchResponse: SearchResponse?
        
        public func getVideos(_ search: String? = nil, _ end: (() -> Void)? = nil) {
            if !isFetching, !isFetchingContination {
                if let search = search {
                    getVideosForSearch(search, end)
                } else {
                    getHomeVideos(end)
                }
            }
        }
        
        public func getVideosContinuation(_ end: (() -> Void)? = nil) {
            if !isFetching, !isFetchingContination {
                if homeResponse != nil {
                    getHomeVideosContinuation(end)
                } else {
                    getSearchVideosContinuation(end)
                }
            }
        }
        
        private func getHomeVideos(_ end: (() -> Void)?) {
            self.homeResponse = nil
            self.searchResponse = nil
            DispatchQueue.main.async {
                self.isFetching = true
                self.error = nil
            }
            HomeScreenResponse.sendNonThrowingRequest(youtubeModel: YTM, data: [:], result: { result in
                switch result {
                case .success(let response):
                    self.homeResponse = response
                    DispatchQueue.main.async {
                        self.items = response.results
                        self.isFetching = false
                        end?()
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.error = error.localizedDescription
                        self.isFetching = false
                        self.items = []
                        end?()
                    }
                }
            })
        }
        
        private func getHomeVideosContinuation(_ end: (() -> Void)?) {
            if let homeResponse = homeResponse, let continuationToken = homeResponse.continuationToken, let visitorData = homeResponse.visitorData {
                DispatchQueue.main.async {
                    self.isFetchingContination = true
                }
                
                HomeScreenResponse.Continuation.sendNonThrowingRequest(youtubeModel: YTM, data: [.continuation: continuationToken, .visitorData: visitorData], result: { result in
                    switch result {
                    case .success(let response):
                        self.homeResponse?.mergeContinuation(response)
                        DispatchQueue.main.async {
                            if let results = self.homeResponse?.results {
                                self.items = results
                                self.isFetchingContination = false
                            }
                            end?()
                        }
                    case .failure(let error):
                        print("Couldn't fetch home screen continuation: \(String(describing: error))")
                        DispatchQueue.main.async {
                            end?()
                        }
                    }
                })
            } else {
                DispatchQueue.main.async {
                    end?()
                }
            }
        }
        
        private func getVideosForSearch(_ search: String, _ end: (() -> Void)?) {
            self.homeResponse = nil
            self.searchResponse = nil
            DispatchQueue.main.async {
                self.isFetching = true
                self.error = nil
            }
            SearchResponse.sendNonThrowingRequest(youtubeModel: YTM, data: [.query: search], result: { result in
                switch result {
                case .success(let response):
                    self.searchResponse = response
                    DispatchQueue.main.async {
                        self.items = response.results
                        self.isFetching = false
                        end?()
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.error = error.localizedDescription
                        self.isFetching = false
                        self.items = []
                        end?()
                    }
                }
            })
        }
        
        private func getSearchVideosContinuation(_ end: (() -> Void)?) {
            if let searchResponse = searchResponse, let continuationToken = searchResponse.continuationToken, let visitorData = searchResponse.visitorData {
                DispatchQueue.main.async {
                    self.isFetchingContination = true
                }
                
                SearchResponse.Continuation.sendNonThrowingRequest(youtubeModel: YTM, data: [.continuation: continuationToken, .visitorData: visitorData], result: { result in
                    switch result {
                    case .success(let response):
                        self.searchResponse?.mergeContinuation(response)
                        DispatchQueue.main.async {
                            if let results = self.searchResponse?.results {
                                self.items = results
                                self.isFetchingContination = false
                            }
                            end?()
                        }
                    case .failure(let error):
                        print("Couldn't fetch search screen continuation: \(String(describing: error))")
                        DispatchQueue.main.async {
                            end?()
                        }
                    }
                })
            } else {
                DispatchQueue.main.async {
                    end?()
                }
            }
        }
    }

    func refreshAutoCompletionEntries() {
        Task {
            let result = try? await AutoCompletionResponse.sendThrowingRequest(youtubeModel: YTM, data: [.query: self.search])
            DispatchQueue.main.async {
                self.autoCompletion = result?.autoCompletionEntries ?? []
            }
        }
    }
}

