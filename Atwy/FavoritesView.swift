//
//  FavoritesView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 02.12.22.
//

import SwiftUI
import CoreData
import YouTubeKit

struct FavoritesView: View {
    @Environment(\.colorScheme) private var colorScheme
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FavoriteVideo.timestamp, ascending: true)],
        animation: .default)
    private var favorites: FetchedResults<FavoriteVideo>
    @State private var search: String = ""
    @ObservedObject private var NPM = NavigationPathModel.shared
    @ObservedObject private var VPM = VideoPlayerModel.shared
    @ObservedObject private var APIM = APIKeyModel.shared
    @ObservedObject private var NM = NetworkReachabilityModel.shared
    @ObservedObject private var PSM = PreferencesStorageModel.shared
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVStack {
                    let videoViewHeight = PSM.videoViewMode == .halfThumbnail ? 180 : geometry.size.width * 9/16 + 90
                    
                    ForEach(sortedVideos) { (video: FavoriteVideo) in
                        let convertedResult = video.toYTVideo()
                        
                        Button {
                            if VideoPlayerModel.shared.currentItem?.videoId != video.videoId {
                                VideoPlayerModel.shared.loadVideo(video: convertedResult)
                            }
                            
                            SheetsModel.shared.showSheet(.watchVideo)
                        } label: {
                            VideoFromSearchView(videoWithData: convertedResult.withData(.init(channelAvatarData: video.channel?.thumbnail, thumbnailData: video.thumbnailData)))
                                .frame(width: geometry.size.width, height: videoViewHeight, alignment: .center)
                        }
                        .listRowSeparator(.hidden)
                    }
                    Color.clear
                        .frame(height: 30)
                }
                if VPM.currentItem != nil {
                    Color.clear
                        .frame(height: 50)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .routeContainer()
#if os(macOS)
        .searchable(text: $search, placement: .toolbar)
#else
        .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always))
#endif
        
        .autocorrectionDisabled(true)
        .navigationTitle("Favorites")
        .sortingModeSelectorButton(forPropertyType: .favoritesSortingMode)
        .customNavigationTitleWithRightIcon {
            ShowSettingsButtonView()
        }
    }
    
    var sortedVideos: [FavoriteVideo] {
        return self.favorites
            .filter({$0.matchesQuery(search)})
            .conditionnalFilter(mainCondition: !NM.connected, {PersistenceModel.shared.isVideoDownloaded(videoId: $0.videoId) != nil})
            .sorted(by: {
                switch self.PSM.favoritesSortingMode {
                case .newest:
                    return $0.timestamp > $1.timestamp
                case .oldest:
                    return $0.timestamp < $1.timestamp
                case .title:
                    return ($0.title ?? "") < ($1.title ?? "")
                case .channelName:
                    return ($0.channel?.name ?? "") < ($1.channel?.name ?? "")
                }
            })
    }
}

struct IsPresentedSearchableModifier: ViewModifier {
    @Binding var search: String
    @Binding var isPresented: Bool
    var placement: SearchFieldPlacement = .automatic
    func body(content: Content) -> some View {
        Group {
            if isPresented {
                content
                    .searchable(text: $search, placement: placement)
            } else {
                content
            }
        }
    }
}

extension View {
    func isPresentedSearchable(search: Binding<String>, isPresented: Binding<Bool>, placement: SearchFieldPlacement = .automatic) -> some View {
        modifier(IsPresentedSearchableModifier(search: search, isPresented: isPresented, placement: placement))
    }
}

struct CController: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        return Controller()
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}

class Controller: UITableViewController {
    
    var favorites: [FavoriteVideo] = []
    
    init() {
        super.init(style: .plain)
        self.tableView.register(VideoCell.self, forCellReuseIdentifier: "VideoCell")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        fetchFavorites()
        self.tableView.dataSource = self
        self.tableView.delegate = self
    }
    
    private func fetchFavorites() {
        let coreContext = PersistenceModel.shared.context
        let fetchRequest = NSFetchRequest<FavoriteVideo>(entityName: "FavoriteVideo")
        do {
            favorites = try coreContext.fetch(fetchRequest)
        } catch let error as NSError {
            print(error.userInfo)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favorites.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VideoCell", for: indexPath) as! VideoCell
        
        let videoViewHeight = PreferencesStorageModel.shared.videoViewMode == .halfThumbnail ? 180 : self.view.frame.size.width * 9/16 + 90
        
        cell.contentView.frame.size = .init(width: self.view.frame.width, height: videoViewHeight)

        // Configure the cell’s contents.
        cell.setNewVideo(favorites[indexPath.row])
                
        return cell
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return PreferencesStorageModel.shared.videoViewMode == .halfThumbnail ? 180 : self.view.frame.size.width * 9/16 + 90
    }
}

class VideoCell: UITableViewCell {
    private var video: FavoriteVideo?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    func setNewVideo(_ video: FavoriteVideo) {
        self.contentView.subviews.forEach {$0.removeFromSuperview()}
        let subview = UIHostingController(rootView: VideoViewww(video: video, size: self.frame.size)).view
        subview!.frame = self.contentView.frame
        self.contentView.addSubview(subview!)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct VideoViewww: View {
    let video: FavoriteVideo
    let size: CGSize
    var body: some View {
        Button {
            if VideoPlayerModel.shared.currentItem?.videoId != video.videoId {
                VideoPlayerModel.shared.loadVideo(video: video.toYTVideo())
            }
            
            SheetsModel.shared.showSheet(.watchVideo)
        } label: {
            VideoFromSearchView(videoWithData: video.toYTVideo().withData(.init(channelAvatarData: video.channel?.thumbnail, thumbnailData: video.thumbnailData)))
        }
        .frame(width: size.width, height: size.height)
    }
}
