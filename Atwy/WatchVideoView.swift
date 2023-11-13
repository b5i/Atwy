//
//  WatchVideoView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 25.11.22.
//

import SwiftUI
import AVKit
#if !os(macOS)
import MediaPlayer
#endif
import CoreAudio
import YouTubeKit

struct NewWatchVideoView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.presentationMode) private var presentationMode
    @State private var topColorGradient: LinearGradient = .init(colors: [.gray, .white], startPoint: .leading, endPoint: .trailing)
    @State private var bottomColorGradient: LinearGradient = .init(colors: [.gray, .white], startPoint: .leading, endPoint: .trailing)
    @State private var animationColors: [Color] = [.white, .gray, .white, .gray]
    @State private var usedAnimationColors: [Color] = [.white, .gray, .white, .gray]
    @State private var animateStartPoint: UnitPoint = .topLeading
    @State private var animateEndPoint: UnitPoint = .bottomTrailing
    @State private var showQueue: Bool = false
    @State private var showDescription: Bool = false
    @Namespace private var animation
    @ObservedObject private var VPM = VideoPlayerModel.shared
    @ObservedObject private var APIM = APIKeyModel.shared
    @ObservedObject private var NRM = NetworkReachabilityModel.shared
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
                        .clipShape(
                            .rect(
                                topLeadingRadius: 0,
                                bottomLeadingRadius: self.screenCornerRadius,
                                bottomTrailingRadius: self.screenCornerRadius,
                                topTrailingRadius: 0
                            )
                        )
                    Rectangle()
                        .fill(LinearGradient(colors: usedAnimationColors, startPoint: animateStartPoint, endPoint: animateEndPoint).shadow(.inner(radius: 5)))
                        .blendMode(.multiply)
                        .clipShape(
                            .rect(
                                topLeadingRadius: 0,
                                bottomLeadingRadius: self.screenCornerRadius,
                                bottomTrailingRadius: self.screenCornerRadius,
                                topTrailingRadius: 0
                            )
                        )
                }
                .ignoresSafeArea(.all)
                .frame(width: geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing, height: geometry.size.height + geometry.safeAreaInsets.bottom + geometry.safeAreaInsets.top)
                .zIndex(0)
                VStack {
                    Spacer()
                    VStack(spacing: 0) {
                        ZStack {
                            ZStack(alignment: (showQueue || showDescription) ? .topLeading : .center) {
                                ZStack {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.3))
                                        .shadow(radius: 10)
                                }
                                //                                .frame(width: geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing, height: (showQueue || showDescription) ? geometry.size.height * 0.40 : geometry.size.height * 0.45)
                                .frame(width: geometry.size.width, height: (showQueue || showDescription) ?  geometry.size.height * 0.175 : geometry.size.height * 0.45)
                                .padding(.top, -geometry.size.height * 0.01)
                                //.padding(.bottom, geometry.size.height * 0.05)
                                //(showQueue || showDescription) ? :
                                HStack(spacing: 0) {
                                    if VPM.player.currentItem != nil {
                                        PlayerViewController(
                                            player: VPM.player,
                                            controller: VPM.controller
                                        )
                                        .frame(width: (showQueue || showDescription) ? geometry.size.width / 2 : geometry.size.width, height: (showQueue || showDescription) ? geometry.size.height * 0.175 : geometry.size.height * 0.35)
                                        .padding(.top, (showQueue || showDescription) ? -geometry.size.height * 0.01 : -geometry.size.height * 0.115)
                                        .shadow(radius: 10)
                                        .onAppear {
                                            if UIApplication.shared.applicationState == .background {
                                                NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil, using: { _ in
                                                    presentationMode.wrappedValue.dismiss()
                                                })
                                            }
                                        }
                                    }
                                    //                                    VideoPlayer(player: player)
                                    //                                        .frame(width: (showQueue || showDescription) ? geometry.size.width / 2 : geometry.size.width, height: (showQueue || showDescription) ? geometry.size.height * 0.175 : geometry.size.height * 0.35)
                                    //                                        .padding(.top, (showQueue || showDescription) ? -geometry.size.height * 0.01 : -geometry.size.height * 0.11)
                                    //                                        .shadow(radius: 10)
                                    if showQueue || showDescription {
                                        ZStack {
                                            VStack(alignment: .leading) {
                                                Text(VPM.video?.title ?? "")
                                                    .font(.system(size: 500))
                                                    .minimumScaleFactor(0.01)
                                                    .matchedGeometryEffect(id: "VIDEO_TITLE", in: animation)
                                                    .frame(height: geometry.size.height * 0.1)
                                                    .transition(.asymmetric(insertion: .offset(y: 100), removal: .offset(y: 100)))
                                                Divider()
                                                    .frame(height: 1)
                                                Text(VPM.video?.channel?.name ?? "")
                                                    .font(.system(size: 500))
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
                                ChannelAvatarView(makeGradient: makeGradient)
                                    .frame(height: (showDescription || showQueue) ? 0 : geometry.size.height * 0.07)
                                    .padding()
                                    .shadow(radius: 5)
                                    .offset(x: (showQueue || showDescription) ? -geometry.size.width * 0.55 : 0, y: (showQueue || showDescription) ? -geometry.size.height * 0.14 : -geometry.size.height * 0.01)
                                if !(showQueue || showDescription) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(VPM.video?.title ?? "")
                                            .frame(width: geometry.size.width * 0.6, height: geometry.size.height * 0.06, alignment: .leading)
                                            .font(.system(size: 500))
                                            .minimumScaleFactor(0.01)
                                            .multilineTextAlignment(.leading)
                                            .matchedGeometryEffect(id: "VIDEO_TITLE", in: animation)
                                        Divider()
                                            .frame(height: 1)
                                        Text(VPM.video?.channel?.name ?? "")
                                            .frame(width: geometry.size.width * 0.6, height: geometry.size.height * 0.03, alignment: .leading)
                                            .font(.system(size: 500))
                                            .minimumScaleFactor(0.01)
                                            .multilineTextAlignment(.leading)
                                            .matchedGeometryEffect(id: "VIDEO_AUTHOR", in: animation)
                                    }
                                    .frame(width: geometry.size.width * 0.6, height: geometry.size.height * 0.09)
                                    .padding()
                                }
                            }
                            .offset(y: geometry.size.height * 0.17)
                        }
                        .ignoresSafeArea()
                        ScrollView(.horizontal) {
                            HStack {
                                Color.clear.frame(width: 10, height: !(showQueue || showDescription) ? 50 : 0)
                                VideoAppreciationView()
                                    .opacity(!(showQueue || showDescription) ? 1 : 0)
                                    .frame(width: VPM.moreVideoInfos?.likesCount.defaultState != "" ? (APIM.userAccount != nil ? 180 : 120) : 0)
                                if NRM.connected {
                                    if let video = VPM.video {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .foregroundStyle(.white)
                                                .opacity(0.3)
                                                .frame(height: 45)
                                            DownloadButtonView(video: video, videoThumbnailData: VPM.videoThumbnailData)
                                                .foregroundStyle(.white)
                                        }
                                        .opacity(!(showQueue || showDescription) ? 1 : 0)
                                        .frame(width: 60)
                                        .padding(.horizontal, 10)
                                        .contextMenu(menuItems: {
                                            if downloads.contains(where: {$0.video?.videoId == video.videoId}) {
                                                Button(role: .destructive) {
                                                    DownloadingsModel.shared.cancelDownloadFor(video.videoId)
                                                } label: {
                                                    HStack {
                                                        Text("Cancel Download")
                                                        Image(systemName: "trash")
                                                    }
                                                }
                                            }
                                        })
                                    }
                                    if let video = VPM.video {
                                        Button {
                                            CoordinationManager.shared.prepareToPlay(video)
                                        } label: {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .foregroundStyle(.white)
                                                    .opacity(0.3)
                                                    .frame(height: 45)
                                                Image(systemName: "shareplay")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 30)
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                        .opacity(!(showQueue || showDescription) ? 1 : 0)
                                        .frame(width: 60)
                                        .padding(.trailing, 10)
                                    }
                                }
                                Color.clear.frame(width: 10, height: !(showQueue || showDescription) ? 50 : 0)
                            }
                        }
                        .scrollIndicators(.hidden)
                        .padding(.vertical, 15)
                        .frame(height: !(showQueue || showDescription) ? 80 : 0)
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
                                if let videoDescription = VPM.streamingInfos?.videoDescription ?? VPM.moreVideoInfos?.videoDescription?.map({$0.text ?? ""}).joined() ?? VPM.videoDescription {
//                                    ChaptersView(geometry: geometry, chapters: getChapterInText(VPM.streamingInfos?.videoDescription ?? ""), chapterAction: {_ in})
                                    ChaptersView(geometry: geometry, chapters: VPM.moreVideoInfos?.chapters?.compactMap({ chapter in
                                        if let time = chapter.startTimeSeconds, let formattedTime = chapter.timeDescriptions.shortTimeDescription, let title = chapter.title {
                                            return Chapter(time: time, formattedTime: formattedTime, title: title)
                                        }
                                        return nil
                                    }) ?? [], chapterAction: { clickedChapter in
                                        VPM.player.seek(to: CMTime(seconds: Double(clickedChapter.time), preferredTimescale: 600))
                                    })
                                    Text(LocalizedStringKey(videoDescription))
                                        .blendMode(.difference)
                                        .padding(.horizontal)
                                    Color.clear.frame(height: 15)
                                }
                            }
                            .mask(FadeInOutView())
                        }
                        .opacity(showDescription ? 1 : 0)
                        .frame(height: showDescription ? geometry.size.height * 0.85 - 120 : 0)
                        VStack {
                            ScrollView {
                                Color.clear.frame(height: 15)
                                PlayingQueueView()
                                Color.clear.frame(height: 15)
                            }
                            .mask(FadeInOutView())
                        }
                        .opacity(showQueue ? 1 : 0)
                        .frame(height: showQueue ? geometry.size.height * 0.85 - 120 : 0)
                        Spacer()
                        HStack {
                            let hasDescription = VPM.streamingInfos?.videoDescription ?? VPM.videoDescription ?? VPM.moreVideoInfos?.videoDescription?.compactMap({$0.text}).joined() ?? "" != ""
                            Spacer()
                            Button {
                                withAnimation(.interpolatingSpring(duration: 0.3)) {
                                    if showQueue {
                                        showQueue = false
                                    }
                                    showDescription.toggle()
                                }
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .foregroundStyle(showDescription ? Color(uiColor: UIColor.lightGray) : .clear)
                                        .animation(nil, value: 0)
                                    Image(systemName: "doc.append")
                                        .resizable()
                                        .foregroundStyle(showDescription ? .white : Color(uiColor: UIColor.lightGray))
                                        .scaledToFit()
                                        .frame(width: showDescription ? 18 : 21)
                                        .blendMode(showDescription ? .exclusion : .screen)
                                }
                                .frame(width: 30, height: 30)
                            }
                            .opacity(hasDescription ? 1 : 0.5)
                            .disabled(!hasDescription)
                            Spacer()
                            Button {
                                
                            } label: {
                                AirPlayButton()
                                    .scaledToFit()
                                    .blendMode(.screen)
                                    .frame(width: 50)
                            }
                            Spacer()
                            Button {
                                withAnimation(.interpolatingSpring(duration: 0.3)) {
                                    if showDescription {
                                        showDescription = false
                                    }
                                    showQueue.toggle()
                                }
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .foregroundStyle(showQueue ? Color(uiColor: UIColor.lightGray) : .clear)
                                        .animation(nil, value: 0)
                                    Image(systemName: "list.bullet")
                                        .resizable()
                                        .foregroundStyle(showQueue ? .white : Color(uiColor: UIColor.lightGray))
                                        .scaledToFit()
                                        .frame(width: showQueue ? 18 : 22)
                                        .blendMode(showQueue ? .exclusion : .screen)
                                }
                                .frame(width: 30, height: 30)
                            }
                            Spacer()
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height * 0.12)
                    }
                    Spacer()
                }
                .zIndex(1)
            }
        }
        .task {
            if let channelAvatar = VPM.streamingInfos?.channel?.thumbnails.first?.url {
                URLSession.shared.dataTask(with: channelAvatar, completionHandler: { data, _, _ in
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            makeGradient(image: image)
                        }
                    } else {
                        print("Couldn't get/create image")
                    }
                })
                .resume()
            }
        }
//        .task {
//            DispatchQueue.main.async {
//                withAnimation(.easeInOut(duration: 14).repeatForever(autoreverses: true)) {
//                    animateStartPoint = animateStartPoint == .topLeading ? .bottomTrailing : .topLeading
//                    animateEndPoint = animateEndPoint == .topLeading ? .bottomTrailing : .topLeading
//                }
//            }
//        }
    }
    
    private struct FadeInOutView: View {
        var body: some View {
            VStack(spacing: 0) {
                
                // Left gradient
                LinearGradient(gradient:
                                Gradient(
                                    colors: [Color.black.opacity(0), Color.black]),
                               startPoint: .top, endPoint: .bottom
                )
                .frame(height: 15)
                
                // Middle
                Rectangle().fill(Color.black)
                
                // Right gradient
                LinearGradient(gradient:
                                Gradient(
                                    colors: [Color.black, Color.black.opacity(0)]),
                               startPoint: .top, endPoint: .bottom
                )
                .frame(height: 15)
            }
        }
    }
    
    private func getChapterInText(_ text: String) -> [Chapter] {
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
        var finalChapters: [Chapter] = []
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
    
    private struct Chapter {
        var time: Int
        var formattedTime: String
        var title: String
    }
    
    private struct ChaptersView: View {
        @State var geometry: GeometryProxy
        @State var chapters: [Chapter]
        @State var chapterAction: (Chapter) -> Void
        
        var body: some View {
            ScrollView {
                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(chapters.enumerated().filter({index, _ in index % 2 == 0})), id: \.offset) { _, chapter in
                            ChapterView(chapter: chapter, chapterAction: chapterAction, geometry: geometry)
                                .frame(width: geometry.size.width * 0.45, height: geometry.size.height * 0.067)
                        }
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(chapters.enumerated().filter({index, _ in index % 2 == 1})), id: \.offset) { _, chapter in
                            ChapterView(chapter: chapter, chapterAction: chapterAction, geometry: geometry)
                                .frame(width: geometry.size.width * 0.45, height: geometry.size.height * 0.067)
                        }
                    }
                }
            }
            .frame(maxHeight: geometry.size.height * 0.2)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .padding([.horizontal, .bottom])
        }
        
        private struct ChapterView: View {
            @State var chapter: Chapter
            @State var chapterAction: (Chapter) -> Void
            @State var geometry: GeometryProxy
            var body: some View {
                Button {
                    chapterAction(chapter)
                } label: {
                    ZStack {
                        Rectangle()
                            .fill(.white.opacity(0.2).shadow(.inner(radius: 5)))
                        VStack(alignment: .leading) {
                            Text(chapter.formattedTime)
                                .font(.caption)
                                .foregroundStyle(.white)
                            Text(chapter.title)
                                .font(.system(size: 20))
                                .minimumScaleFactor(0.05)
                                .foregroundStyle(.white)
                        }
                        .padding(5)
                    }
                }
            }
        }
    }
    
    private func changeColors() {
        Task {
            //            sleep(29)
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 29)) {
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
        
        DispatchQueue.main.async {
            withAnimation {
                self.topColorGradient = .init(colors: [Color(TLColor ?? .white), Color(TTColor ?? .white)], startPoint: .leading, endPoint: .trailing)
                self.bottomColorGradient = .init(colors: [Color(BLColor ?? .white), Color(BTColor ?? .white)], startPoint: .leading, endPoint: .trailing)
                self.animationColors = [Color(TLColor ?? .white), Color(TTColor ?? .white), Color(BLColor ?? .white), Color(BTColor ?? .white)]
                self.usedAnimationColors = self.animationColors
            }
        }
    }
    
    struct NoChannelAvatarView: View {
        var body: some View {
            GeometryReader { geometry in
                ZStack {
                    Circle()
                        .foregroundStyle(.gray)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.white)
                        .shadow(radius: 3)
                        .frame(width: geometry.size.width * 0.5)
                }
            }
        }
    }
    
    struct ChannelAvatarView: View {
        let makeGradient: (UIImage) -> Void
        @State private var isFetching: Bool = false
        @ObservedObject private var VPM = VideoPlayerModel.shared
        @ObservedObject private var APIM = APIKeyModel.shared
        var body: some View {
            ZStack {
                if let channelAvatar = (VPM.streamingInfos?.channel?.thumbnails.maxFor(2) ?? VPM.moreVideoInfos?.channel?.thumbnails.maxFor(2)) ?? VPM.video?.channel?.thumbnails.maxFor(2) {
                    CachedAsyncImage(url: channelAvatar.url) { image in
                        switch image {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .clipShape(Circle())
                                .task {
                                    URLSession.shared.dataTask(with: channelAvatar.url, completionHandler: { data, _, _ in
                                        if let data = data, let image = UIImage(data: data) {
                                            makeGradient(image)
                                        } else {
                                            print("Couldn't get/create image")
                                        }
                                    })
                                    .resume()
                                }
                                .overlay(alignment: .bottomTrailing, content: {
                                    if let subscriptionStatus = VPM.moreVideoInfos?.authenticatedInfos?.subscriptionStatus, let channel = VPM.moreVideoInfos?.channel {
                                        if APIM.userAccount != nil && APIM.googleCookies != "" {
                                            if isFetching {
                                                ZStack {
                                                    Circle()
                                                        .foregroundStyle(.gray)
                                                    ProgressView()
                                                        .padding(.horizontal)
                                                        .frame(width: 10, height: 10)
                                                }
                                                .frame(width: 24, height: 24)
                                                .clipShape(Circle())
                                                .offset(x: 10, y: 7)
                                                .shadow(radius: 3)
                                            } else {
                                                if subscriptionStatus {
                                                    Button {
                                                        DispatchQueue.main.async {
                                                            self.isFetching = true
                                                        }
                                                        channel.unsubscribe(youtubeModel: YTM, result: { error in
                                                            if let error = error {
                                                                print("Error while unsubscribing to channel: \(error)")
                                                            } else {
                                                                VPM.moreVideoInfos?.authenticatedInfos?.subscriptionStatus = false
                                                            }
                                                            DispatchQueue.main.async {
                                                                self.isFetching = false
                                                            }
                                                        })
                                                    } label: {
                                                        ZStack(alignment: .center) {
                                                            Rectangle()
                                                                .foregroundStyle(.white)
                                                                .frame(width: 23, height: 23)
                                                            Image(systemName: "checkmark.circle.fill")
                                                                .resizable()
                                                                .scaledToFit()
                                                                .foregroundColor(.green)
                                                                .frame(width: 25, height: 25)
                                                        }
                                                    }
                                                    .background(.white)
                                                    .buttonStyle(.borderedProminent)
                                                    .frame(width: 24, height: 24)
                                                    .clipShape(Circle())
                                                    .offset(x: 10, y: 7)
                                                    .shadow(radius: 3)
                                                } else {
                                                    Button {
                                                        DispatchQueue.main.async {
                                                            self.isFetching = true
                                                        }
                                                        channel.subscribe(youtubeModel: YTM, result: { error in
                                                            if let error = error {
                                                                print("Error while subscribing to channel: \(error)")
                                                            } else {
                                                                VPM.moreVideoInfos?.authenticatedInfos?.subscriptionStatus = false
                                                            }
                                                            DispatchQueue.main.async {
                                                                self.isFetching = false
                                                            }
                                                        })
                                                    } label: {
                                                        ZStack(alignment: .center) {
                                                            Rectangle()
                                                                .foregroundStyle(.white)
                                                                .frame(width: 23, height: 23)
                                                            Image(systemName: "plus.circle.fill")
                                                                .resizable()
                                                                .scaledToFit()
                                                                .foregroundColor(.red)
                                                                .frame(width: 25, height: 25)
                                                        }
                                                    }
                                                    .buttonStyle(.borderedProminent)
                                                    .frame(width: 24, height: 24)
                                                    .clipShape(Circle())
                                                    .offset(x: 10, y: 7)
                                                    .shadow(radius: 3)
                                                }
                                            }
                                        }
                                    }
                                })
                        case .empty, .failure(_):
                            NoAvatarCircle(makeGradient: makeGradient)
                        @unknown default:
                            NoAvatarCircle(makeGradient: makeGradient)
                        }
                    }
                } else {
                    NoAvatarCircle(makeGradient: makeGradient)
                }
            }
        }
        
        public struct NoAvatarCircle: View {
            let makeGradient: (UIImage) -> Void
            var body: some View {
                ZStack {
                    Circle()
                        .foregroundStyle(.gray)
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundStyle(.white)
                        .task {
                            let renderer = ImageRenderer(content: NoChannelAvatarView())
                            if let uiImage = renderer.uiImage {
                                makeGradient(uiImage)
                            }
                        }
                }
                .clipShape(Circle())
            }
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


