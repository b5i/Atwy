//
//  WatchVideoView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 25.11.22.
//  Copyright © 2023-2025 Antoine Bollengier. All rights reserved.
//

import SwiftUI
import AVKit
#if !os(macOS)
import MediaPlayer
#endif
import CoreAudio
import YouTubeKit

struct WatchVideoView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var topColorGradient: LinearGradient = .init(colors: [.gray, .white], startPoint: .leading, endPoint: .trailing)
    @State private var bottomColorGradient: LinearGradient = .init(colors: [.gray, .white], startPoint: .leading, endPoint: .trailing)
    @State private var animationColors: [Color] = [.white, .gray, .white, .gray]
    @State private var meshColors: [Color] = [.white, .gray, .white, .gray, .white, .gray, .white, .gray, .white]
    @State private var meshUsedColors: [Color] = [.white, .gray, .white, .gray, .white, .gray, .white, .gray, .white]
    @State private var usedAnimationColors: [Color] = [.white, .gray, .white, .gray]
    @State private var animateStartPoint: UnitPoint = .topLeading
    @State private var animateEndPoint: UnitPoint = .bottomTrailing
    @State private var showQueue: Bool = false {
        willSet {
            if showDescription {
                showDescription = false
            }
            
            if showComments {
                showComments = false
            }
        }
    }
    @State private var showDescription: Bool = false {
        willSet {
            if showQueue {
                showQueue = false
            }
            
            if showComments {
                showComments = false
            }
        }
    }
    @State private var showComments: Bool = false {
        willSet {
            if showDescription {
                showDescription = false
            }
            if showQueue {
                showQueue = false
            }
        }
    }
    @Namespace private var animation
    @ObservedObject private var VPM = VideoPlayerModel.shared
    @ObservedObject private var APIM = APIKeyModel.shared
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                //                    Rectangle()
                //                        .fill(Color.init(cgColor: .init(red: 0.96, green: 0.96, blue: 1, alpha: 1)))
                //                        .frame(width: geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing, height: geometry.size.height + geometry.safeAreaInsets.bottom + geometry.safeAreaInsets.top)
                ZStack {
                    Rectangle()
                        .fill(Gradient(stops: [
                            .init(color: (colorScheme == .light ? Color.black.opacity(0.15) : Color.white.opacity(0.85)), location: 0),
                            .init(color: (colorScheme == .light ? Color.black.opacity(0.25) : Color.white.opacity(0.75)), location: 0.7),
                            .init(color: (colorScheme == .light ? Color.black.opacity(0.65) : Color.white.opacity(0.35)), location: 1)
                        ]))
                    if #available(iOS 18.0, *) {
                        Rectangle()
                            .fill(
                                MeshGradient(width: 3, height: 3, points: [.init(0.0, 0.0), .init(0.5, 0.0), .init(1.0, 0.0), .init(0.0, 0.5), .init(0.5, 0.5), .init(1.0, 0.5), .init(0.0, 1.0), .init(0.5, 1.0), .init(1.0, 1.0)], colors: self.meshUsedColors, smoothsColors: true)
                            )
                            .blendMode(.multiply)
                    } else {
                        Rectangle()
                            .fill(LinearGradient(colors: usedAnimationColors, startPoint: animateStartPoint, endPoint: animateEndPoint).shadow(.inner(radius: 5)))
                            .blendMode(.multiply)
                    }
                }
                .ignoresSafeArea(.all)
                .frame(width: geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing, height: geometry.size.height + geometry.safeAreaInsets.bottom + geometry.safeAreaInsets.top)
                .zIndex(0)
                VStack {
                    Spacer()
                    VStack(spacing: 0) {
                        let topMenuShown = showQueue || showDescription || showComments
                        VStack {
                            ZStack {
                                ZStack(alignment: topMenuShown ? .topLeading : .center) {
                                    ZStack {
                                        Rectangle()
                                            .fill(Color.black.opacity(0.4))
                                            .shadow(radius: 10)
                                    }
                                    //                                .frame(width: geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing, height: menuShown ? geometry.size.height * 0.40 : geometry.size.height * 0.45)
                                    .frame(width: geometry.size.width, height: topMenuShown ?  geometry.size.height * 0.175 : geometry.size.height * 0.45)
                                    .padding(.top, -geometry.size.height * 0.01)
                                    //.padding(.bottom, geometry.size.height * 0.05)
                                    //(showQueue || showDescription) ? :
                                    HStack(spacing: 0) {
                                        if VPM.player.currentItem != nil {
                                            PlayerViewController(
                                                player: VPM.player,
                                                controller: VPM.controller
                                            )
                                            .frame(width: topMenuShown ? geometry.size.width / 2 : geometry.size.width, height: topMenuShown ? geometry.size.height * 0.175 : geometry.size.height * 0.35)
                                            .padding(.top, topMenuShown ? -geometry.size.height * 0.01 : -geometry.size.height * 0.115)
                                            .shadow(radius: 10)
                                            
                                        } else if VPM.isLoadingVideo {
                                            LoadingView(style: .light)
                                                .frame(alignment: .center)
                                        }
                                        //                                    VideoPlayer(player: player)
                                        //                                        .frame(width: menuShown ? geometry.size.width / 2 : geometry.size.width, height: menuShown ? geometry.size.height * 0.175 : geometry.size.height * 0.35)
                                        //                                        .padding(.top, menuShown ? -geometry.size.height * 0.01 : -geometry.size.height * 0.11)
                                        //                                        .shadow(radius: 10)
                                        if topMenuShown {
                                            ZStack {
                                                VStack(alignment: .leading) {
                                                    Text(VPM.currentItem?.video.title ?? "")
                                                        .font(.system(size: 500))
                                                        .foregroundStyle(.white)
                                                        .minimumScaleFactor(0.01)
                                                        .matchedGeometryEffect(id: "VIDEO_TITLE", in: animation)
                                                        .frame(height: geometry.size.height * 0.1)
                                                        .transition(.asymmetric(insertion: .offset(y: 100), removal: .offset(y: 100)))
                                                    Divider()
                                                        .frame(height: 1)
                                                    Text(VPM.currentItem?.video.channel?.name ?? "")
                                                        .font(.system(size: 500))
                                                        .foregroundStyle(.white)
                                                        .minimumScaleFactor(0.01)
                                                        .matchedGeometryEffect(id: "VIDEO_AUTHOR", in: animation)
                                                        .frame(height: geometry.size.height * 0.05)
                                                        .transition(.asymmetric(insertion: .offset(y: 100), removal: .offset(y: 100)))
                                                }
                                                .padding(.horizontal)
                                            }
                                            .frame(width: geometry.size.width / 2, height: geometry.size.height * 0.175)
                                            .padding(.top, -geometry.size.height * 0.01)
                                        }
                                    }
                                }
                                .zIndex(0)
                                HStack(alignment: .bottom) {
                                    OptionalItemChannelAvatarView(makeGradient: makeGradient)
                                        .padding(.horizontal)
                                        .frame(height: topMenuShown ? 0 : geometry.size.height * 0.07)
                                        .padding(.vertical)
                                        .shadow(radius: 5)
                                        .offset(x: topMenuShown ? -geometry.size.width * 0.55 : 0, y: topMenuShown ? -geometry.size.height * 0.15 : -geometry.size.height * 0.01)
                                    if !topMenuShown {
                                        VStack(alignment: .leading, spacing: 2) {
                                            let videoTitle = VPM.currentItem?.videoTitle ?? VPM.loadingVideo?.title ?? ""
                                            Text(videoTitle)
                                                .font(.callout)
                                                .foregroundStyle(.white)
                                                .lineLimit(2)
                                                .padding(.trailing)
                                                .frame(maxWidth: geometry.size.width * 0.77, maxHeight: geometry.size.height * 0.065, alignment: .leading)
                                                .multilineTextAlignment(.leading)
                                                .matchedGeometryEffect(id: "VIDEO_TITLE", in: animation)
                                            
                                            let channelName: String = VPM.currentItem?.channelName ?? VPM.loadingVideo?.channel?.name ?? ""
                                            Text(channelName)
                                                .font(.subheadline)
                                                .lineLimit(2)
                                                .padding(.trailing)
                                                .frame(maxWidth: geometry.size.width * 0.77, maxHeight: geometry.size.height * 0.035, alignment: .leading)
                                                .multilineTextAlignment(.leading)
                                                .foregroundStyle(.gray)
                                                .matchedGeometryEffect(id: "VIDEO_AUTHOR", in: animation)
                                            //                                        Text(VPM.video?.title ?? "")
                                            //                                            .frame(width: geometry.size.width * 0.6, height: geometry.size.height * 0.06, alignment: .leading)
                                            //                                            .font(.system(size: 500))
                                            //                                            .minimumScaleFactor(0.01)
                                            //                                            .multilineTextAlignment(.leading)
                                            //                                            .matchedGeometryEffect(id: "VIDEO_TITLE", in: animation)
                                            //                                        Text(VPM.video?.channel?.name ?? "")
                                            //                                            .frame(width: geometry.size.width * 0.6, height: geometry.size.height * 0.03, alignment: .leading)
                                            //                                            .font(.system(size: 500))
                                            //                                            .minimumScaleFactor(0.01)
                                            //                                            .multilineTextAlignment(.leading)
                                            //                                            .matchedGeometryEffect(id: "VIDEO_AUTHOR", in: animation)
                                        }
                                        .padding(.leading)
                                        .frame(width: geometry.size.width * 0.77, height: geometry.size.height * 0.09)
                                        .padding(.vertical)
                                    }
                                }
                                .offset(y: geometry.size.height * 0.165)
                            }
                            .ignoresSafeArea()
                        }
                        let bottomBarHeight: CGFloat = geometry.safeAreaInsets.bottom + 60
                        GeometryReader { scrollViewGeometry in
                            if let playerItem = self.VPM.currentItem {
                                RecommendedVideosView(playerItem: playerItem)
                                    .frame(height: !topMenuShown ? max(180, scrollViewGeometry.size.height) : 0)
                                    .mask(FadeInOutView(mode: .vertical, gradientSize: 20))
                                    .environment(\.colorScheme, .dark)
                            }
                            VStack {
                                ScrollView {
                                    Color.clear.frame(height: 15)
                                    //                                if let videoDescriptionParts = VPM.moreVideoInfos?.videoDescription {
                                    //                                    HStack {
                                    //                                        ForEach(Array(videoDescriptionParts.enumerated()), id: \.offset) { (index: Int, descriptionPart: YouTubeDescriptionPart) in
                                    //                                            switch descriptionPart.role {
                                    //                                            case .link(let linkURL):
                                    //                                                Link(descriptionPart.text, destination: linkURL)
                                    //                                            case .video:
                                    //                                            default:
                                    //                                                Color.clear.frame(width: 0, height: 0)
                                    //                                            }
                                    //                                        }
                                    //                                    }
                                    //                            }
                                    if let playerItem = VPM.currentItem, let videoDescription = playerItem.videoDescription {
                                        ChaptersView(geometry: geometry, chapterAction: { clickedChapter in
                                            VPM.player.seek(to: CMTime(seconds: Double(clickedChapter.time), preferredTimescale: 600))
                                        }, videoItem: playerItem)
                                        HStack {
                                            Text("Description")
                                                .foregroundColor(.gray)
                                                .font(.caption)
                                            Spacer()
                                        }
                                        .padding([.bottom, .leading])
                                        Text(LocalizedStringKey(videoDescription))
                                            .blendMode(.difference)
                                            .padding(.horizontal)
                                            .foregroundStyle(.white)
                                        Color.clear.frame(height: 15)
                                    }
                                }
                                .mask(FadeInOutView(mode: .vertical))
                            }
                            .opacity(showDescription ? 1 : 0)
                            .frame(height: showDescription ? scrollViewGeometry.size.height : 0)
                            PlayingQueueView()
                                .opacity(showQueue ? 1 : 0)
                                .frame(height: showQueue ? geometry.size.height * 0.85 : 0)
                            if let currentItem = VPM.currentItem {
                                CommentsSectionView(currentItem: currentItem)
                                    .opacity(showComments ? 1 : 0)
                                    .frame(height: showComments ? geometry.size.height * 0.85 : 0)
                                    .mask(FadeInOutView(mode: .vertical, gradientSize: 15))
                            }
                            Spacer()
                        }
                        .contentMargins(.bottom, length: bottomBarHeight)
                        .contentMargins(.top, length: !topMenuShown ? 80 : 0)
                        .overlay(alignment: .top) {
                            PlayerTopActionsView(menuShown: topMenuShown)
                        }
                        .overlay(alignment: .bottom) {
                            PlayerBottomBarView(showDescription: $showDescription, showComments: $showComments, showQueue: $showQueue)
                                .frame(height: bottomBarHeight)
                        }
                        .ignoresSafeArea()
                    }
                    Spacer()
                }
                .zIndex(1)
                .ignoresSafeArea()
            }
        }
        .onReceive(of: .atwyDismissPlayerSheet, handler: { _ in
            dismiss()
        })
//        .task {
//            if let channelAvatar = VPM.streamingInfos?.channel?.thumbnails.first?.url {
//                URLSession.shared.dataTask(with: channelAvatar, completionHandler: { data, _, _ in
//                    if let data = data, let image = UIImage(data: data) {
//                        DispatchQueue.main.async {
//                            makeGradient(image: image)
//                        }
//                    } else {
//                        Logger.atwyLogs.simpleLog("Couldn't get/create image")
//                    }
//                })
//                .resume()
//            } else if let channelAvatarData = VPM.channelAvatarData, let image = UIImage(data: channelAvatarData) {
//                DispatchQueue.main.async {
//                    makeGradient(image: image)
//                }
//            }
//        }
//        .task {
//            DispatchQueue.main.async {
//                withAnimation(.easeInOut(duration: 14).repeatForever(autoreverses: true)) {
//                    animateStartPoint = animateStartPoint == .topLeading ? .bottomTrailing : .topLeading
//                    animateEndPoint = animateEndPoint == .topLeading ? .bottomTrailing : .topLeading
//                }
//            }
//        }
    }
    
    private func getChapterInText(_ text: String) -> [YTAVPlayerItem.Chapter] {
//        00:00 - intro
//        00:00- intro
//        00:00 intro
//        00:00 intro
//        00:00 -intro
//        00:00 - 06:50 : intro
//        00:00—01:18: Intro
        let timeRegex = try! NSRegularExpression(pattern: "([0-9]+:[0-9]+:?[0-9]*)")
        let chapterBeforeTitleRegex = try! NSRegularExpression(pattern: "([0-9]+:[0-9]+:?[0-9]* ?—?-? ?([0-9]+:[0-9]+:?[0-9]*)?( : )?)")
        let chapterTitleRegex = try! NSRegularExpression(pattern: "([0-9]+:[0-9]+:?[0-9]* ?—?-? ?([0-9]+:[0-9]+:?[0-9]*)?( : )?)(.*)")
        var chapterBeforeTitleMatches: [String] = chapterBeforeTitleRegex.matches(in: text, range: .init(text.startIndex..., in: text)).map({ match in
            return (text as NSString).substring(with: match.range) as String
        })
        let chapterTitleMatches: [String] = chapterTitleRegex.matches(in: text, range: .init(text.startIndex..., in: text)).map({ match in
            return (text as NSString).substring(with: match.range) as String
        })
        var finalChapters: [YTAVPlayerItem.Chapter] = []
        if chapterBeforeTitleMatches.count == chapterTitleMatches.count * 2 {
            var newChapterBeforeTitleMatches: [String] = []
            for i in 0..<chapterBeforeTitleMatches.count {
                newChapterBeforeTitleMatches.append(chapterBeforeTitleMatches[i*2])
            }
            chapterBeforeTitleMatches = newChapterBeforeTitleMatches
        } else if chapterBeforeTitleMatches.count != chapterTitleMatches.count { return [] }
        for (index, chapter) in chapterBeforeTitleMatches.enumerated() {
            let chapterTime: String = timeRegex.matches(in: chapter, range: .init(chapter.startIndex..., in: chapter)).map({ match in
                return (chapter as NSString).substring(with: match.range) as String
            })[0]
            let splittedChapterTime = chapterTime.components(separatedBy: ":")
            var time: Int = 0
            for (index, timeComponent) in splittedChapterTime.reversed().enumerated() {
                if let timeComponent = Int(timeComponent) {
                    time += Int(NSDecimalNumber(decimal: pow(60, index)).int32Value) * timeComponent
                }
            }
            finalChapters.append(
                .init(
                    time: time,
                    formattedTime: chapterTime,
                    title: String(chapterTitleMatches[index].dropFirst(chapterBeforeTitleMatches[index].count))
                )
            )
        }
        
        return finalChapters
    }
    
    private struct ChaptersView: View {
        typealias Chapter = YTAVPlayerItem.Chapter
        let geometry: GeometryProxy
        let chapterAction: (Chapter) -> Void
        @State private var lastScrolled: Int = 0
        
        @ObservedObject var videoItem: YTAVPlayerItem
        var body: some View {
            VStack {
                if let chapters = videoItem.chapters,
                    !chapters.isEmpty {
                    HStack {
                        Text("Chapters")
                            .foregroundColor(.gray)
                            .font(.caption)
                        Spacer()
                    }
                    .padding([.bottom, .leading])
                    ScrollViewReader { scrollProxy in
                        ScrollView([.horizontal]) {
                            HStack(alignment: .top, spacing: 0) {
                                ForEach(Array(chapters.enumerated()), id: \.offset) { _, chapter in
                                    ChapterView(chapter: chapter, chapterAction: chapterAction, geometry: geometry)
                                        .frame(width: geometry.size.width * 0.45)
                                        .padding(.trailing)
                                }
                            }
                        }
                        .frame(maxHeight: geometry.size.height * 0.2)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .padding([.horizontal, .bottom])
                        .scrollIndicators(.hidden)
                        .onAppear {
                            VideoPlayerModel.shared.player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { time in
                                if let nextChapter = chapters.last(where: {Int(time.seconds) >= $0.time}), nextChapter.time != lastScrolled {
                                    lastScrolled = nextChapter.time
                                    withAnimation(.spring) {
                                        scrollProxy.scrollTo("WatchVideoViewChapters-\(nextChapter.time)", anchor: .leading)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        private struct ChapterView: View {
            let chapter: Chapter
            var chapterAction: (Chapter) -> Void
            let geometry: GeometryProxy
            var body: some View {
                Button {
                    chapterAction(chapter)
                } label: {
                    ZStack {
                        VStack {
                            Group {
                                if let imageData = chapter.thumbnailData, let image = UIImage(data: imageData) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .aspectRatio(16/9, contentMode: .fit)
                                } else if let imageURL = chapter.thumbnailURLs?.last?.url {
                                    CachedAsyncImage(url: imageURL) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .aspectRatio(16/9, contentMode: .fit)
                                    } placeholder: {
                                        RectangularThumbnailPlaceholderView()
                                    }
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(alignment: .bottomTrailing, content: {
                                if let timeDescription = chapter.formattedTime {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 5)
                                            .opacity(0.9)
                                            .foregroundColor(.black)
                                        Text(timeDescription)
                                            .bold()
                                            .foregroundColor(.white)
                                            .font(.system(size: 14))
                                    }
                                    .frame(width: CGFloat(timeDescription.count) * 10, height: 20)
                                    .padding(3)
                                }
                            })
                            if let title = chapter.title {
                                HStack {
                                    Text(title)
                                        .font(.system(size: 13))
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(2)
                                        .truncationMode(.tail)
                                        .foregroundStyle(.white)
                                        .frame(alignment: .leading)
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .id("WatchVideoViewChapters-\(chapter.time)")
            }
        }
    }
    
    private func changeColors() {
        Task {
            //            sleep(29)
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 29)) {
                    meshUsedColors = meshColors.shuffled()
                    usedAnimationColors = animationColors.shuffled().dropLast((0..<animationColors.count - 1).randomElement() ?? 0)
                }
            }
            sleep(30)
            changeColors()
        }
    }
    
    private func makeGradient(image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        let topLeadingImage = cgImage.cropping(to: CGRect(x: 0, y: 0, width: image.size.width / 2, height: image.size.height / 2))
        let bottomLeadingImage = cgImage.cropping(to: CGRect(x: 0, y: image.size.height / 2, width: image.size.width / 2, height: image.size.height))
        let topTrailingImage = cgImage.cropping(to: CGRect(x: image.size.width / 2, y: 0, width: image.size.width, height: image.size.height / 2))
        let bottomTrailingImage = cgImage.cropping(to: CGRect(x: image.size.width / 2, y: image.size.height / 2, width: image.size.width, height: image.size.height))
        
        guard let topLeadingImage = topLeadingImage, let bottomLeadingImage = bottomLeadingImage, let topTrailingImage = topTrailingImage, let bottomTrailingImage = bottomTrailingImage else { return }
        
        let TLColor = topLeadingImage.findAverageColor(algorithm: .simple)
        let BLColor = bottomLeadingImage.findAverageColor(algorithm: .simple)
        let TTColor = topTrailingImage.findAverageColor(algorithm: .simple)
        let BTColor = bottomTrailingImage.findAverageColor(algorithm: .simple)
        
        // add nine colors to the self.meshColors property, 4 calculated and 5 random ones between that are close to one of the 4
        
        var randomColors: [Color] = []
        
        for _ in 0..<5 {
            let randomBaseColor = self.animationColors.randomElement()!
            let secondRandomBaseColor = self.animationColors.randomElement()!
            if #available(iOS 18.0, *) {
                let randomColor = randomBaseColor.mix(with: secondRandomBaseColor, by: 0.5)
                randomColors.append(randomColor)

            }
        }
        
        DispatchQueue.main.async {
            self.animationColors = [Color(TLColor ?? .white), Color(TTColor ?? .white), Color(BLColor ?? .white), Color(BTColor ?? .white)]
            withAnimation {
                self.topColorGradient = .init(colors: [Color(TLColor ?? .white), Color(TTColor ?? .white)], startPoint: .leading, endPoint: .trailing)
                self.bottomColorGradient = .init(colors: [Color(BLColor ?? .white), Color(BTColor ?? .white)], startPoint: .leading, endPoint: .trailing)
                self.usedAnimationColors = self.animationColors
                
                if self.meshColors.count >= 4 {
                    if self.meshColors[0] != self.animationColors[0] || self.meshColors[1] != self.animationColors[1] || self.meshColors[2] != self.animationColors[2] || self.meshColors[3] != self.animationColors[3] {
                        self.meshColors = self.animationColors.appending(contentsOf: randomColors)
                        self.meshUsedColors = self.meshColors.shuffled()
                    }
                }
            }
            
            //self.meshUsedColors = self.meshColors.shuffled()
        }
    }
}

extension Array {
    func maxFor(_ index: Int) -> Element? {
        return self.count > index ? self[index] : index != 0 ? maxFor(index-1) : nil
    }
}

/// From https://christianselig.com/2021/04/efficient-average-color/
extension CGImage {
    /// There are two main ways to get the color from an image, just a simple "sum up an average" or by squaring their sums. Each has their advantages, but the 'simple' option *seems* better for average color of entire image and closely mirrors CoreImage. Details: https://sighack.com/post/averaging-rgb-colors-the-right-way
    enum AverageColorAlgorithm {
        case simple
        case squareRoot
    }
    
    func findAverageColor(algorithm: AverageColorAlgorithm = .simple) -> UIColor? {
        // First, resize the image. We do this for two reasons, 1) less pixels to deal with means faster calculation and a resized image still has the "gist" of the colors, and 2) the image we're dealing with may come in any of a variety of color formats (CMYK, ARGB, RGBA, etc.) which complicates things, and redrawing it normalizes that into a base color format we can deal with.
        // 40x40 is a good size to resize to still preserve quite a bit of detail but not have too many pixels to deal with. Aspect ratio is irrelevant for just finding average color.
        let size = CGSize(width: 40, height: 40)
        
        let width = Int(size.width)
        let height = Int(size.height)
        let totalPixels = width * height
        
        guard totalPixels != 0 else { return nil }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        // ARGB format
        let bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        
        // 8 bits for each color channel, we're doing ARGB so 32 bits (4 bytes) total, and thus if the image is n pixels wide, and has 4 bytes per pixel, the total bytes per row is 4n. That gives us 2^8 = 256 color variations for each RGB channel or 256 * 256 * 256 = ~16.7M color options in total. That seems like a lot, but lots of HDR movies are in 10 bit, which is (2^10)^3 = 1 billion color options!
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: colorSpace, bitmapInfo: bitmapInfo) else { return nil }

        // Draw our resized image
        context.draw(self, in: CGRect(origin: .zero, size: size))

        guard let pixelBuffer = context.data else { return nil }
        
        // Bind the pixel buffer's memory location to a pointer we can use/access
        let pointer = pixelBuffer.bindMemory(to: UInt32.self, capacity: width * height)

        // Keep track of total colors (note: we don't care about alpha and will always assume alpha of 1, AKA opaque)
        var totalRed = 0
        var totalBlue = 0
        var totalGreen = 0
        
        // Column of pixels in image
        for x in 0 ..< width {
            // Row of pixels in image
            for y in 0 ..< height {
                // To get the pixel location just think of the image as a grid of pixels, but stored as one long row rather than columns and rows, so for instance to map the pixel from the grid in the 15th row and 3 columns in to our "long row", we'd offset ourselves 15 times the width in pixels of the image, and then offset by the amount of columns
                let pixel = pointer[(y * width) + x]
                
                let r = red(for: pixel)
                let g = green(for: pixel)
                let b = blue(for: pixel)

                switch algorithm {
                case .simple:
                    totalRed += Int(r)
                    totalBlue += Int(b)
                    totalGreen += Int(g)
                case .squareRoot:
                    totalRed += Int(pow(CGFloat(r), CGFloat(2)))
                    totalGreen += Int(pow(CGFloat(g), CGFloat(2)))
                    totalBlue += Int(pow(CGFloat(b), CGFloat(2)))
                }
            }
        }
        
        let averageRed: CGFloat
        let averageGreen: CGFloat
        let averageBlue: CGFloat
        
        switch algorithm {
        case .simple:
            averageRed = CGFloat(totalRed) / CGFloat(totalPixels)
            averageGreen = CGFloat(totalGreen) / CGFloat(totalPixels)
            averageBlue = CGFloat(totalBlue) / CGFloat(totalPixels)
        case .squareRoot:
            averageRed = sqrt(CGFloat(totalRed) / CGFloat(totalPixels))
            averageGreen = sqrt(CGFloat(totalGreen) / CGFloat(totalPixels))
            averageBlue = sqrt(CGFloat(totalBlue) / CGFloat(totalPixels))
        }
        
        // Convert from [0 ... 255] format to the [0 ... 1.0] format UIColor wants
        return UIColor(red: averageRed / 255.0, green: averageGreen / 255.0, blue: averageBlue / 255.0, alpha: 1.0)
    }
    
    private func red(for pixelData: UInt32) -> UInt8 {
        // For a quick primer on bit shifting and what we're doing here, in our ARGB color format image each pixel's colors are stored as a 32 bit integer, with 8 bits per color chanel (A, R, G, and B).
        //
        // So a pure red color would look like this in bits in our format, all red, no blue, no green, and 'who cares' alpha:
        //
        // 11111111 11111111 00000000 00000000
        //  ^alpha   ^red     ^blue    ^green
        //
        // We want to grab only the red channel in this case, we don't care about alpha, blue, or green. So we want to shift the red bits all the way to the right in order to have them in the right position (we're storing colors as 8 bits, so we need the right most 8 bits to be the red). Red is 16 points from the right, so we shift it by 16 (for the other colors, we shift less, as shown below).
        //
        // Just shifting would give us:
        //
        // 00000000 00000000 11111111 11111111
        //  ^alpha   ^red     ^blue    ^green
        //
        // The alpha got pulled over which we don't want or care about, so we need to get rid of it. We can do that with the bitwise AND operator (&) which compares bits and the only keeps a 1 if both bits being compared are 1s. So we're basically using it as a gate to only let the bits we want through. 255 (below) is the value we're using as in binary it's 11111111 (or in 32 bit, it's 00000000 00000000 00000000 11111111) and the result of the bitwise operation is then:
        //
        // 00000000 00000000 11111111 11111111
        // 00000000 00000000 00000000 11111111
        // -----------------------------------
        // 00000000 00000000 00000000 11111111
        //
        // So as you can see, it only keeps the last 8 bits and 0s out the rest, which is what we want! Woohoo! (It isn't too exciting in this scenario, but if it wasn't pure red and was instead a red of value "11010010" for instance, it would also mirror that down)
        return UInt8((pixelData >> 16) & 255)
    }

    private func green(for pixelData: UInt32) -> UInt8 {
        return UInt8((pixelData >> 8) & 255)
    }

    private func blue(for pixelData: UInt32) -> UInt8 {
        return UInt8((pixelData >> 0) & 255)
    }
}

struct AirPlayButton: UIViewRepresentable {
    
    func makeUIView(context: Context) -> AVRoutePickerView {
        let routePickerView = AVRoutePickerView()
        routePickerView.tintColor = UIColor.lightGray

        routePickerView.prioritizesVideoDevices = true
        return routePickerView
    }
    
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
    
    typealias UIViewType = AVRoutePickerView
}
