//
//  CommentsSectionView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 10.01.2025.
//  Copyright © 2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI
import YouTubeKit
import OSLog

struct CommentsSectionView: View {
    @ObservedObject var currentItem: YTAVPlayerItem
    
    var body: some View {
        Group {
            if currentItem.isFetchingComments == true && currentItem.moreVideoInfos != nil {
                LoadingView(style: .light)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else if currentItem.comments == nil && self.currentItem.moreVideoInfos != nil {
                Color.clear
                    .onAppear {
                        currentItem.fetchVideoComments()
                    }
            } else if currentItem.comments != nil {
                ScrollView {
                    LazyVStack {
                        ForEach(currentItem.comments?.results ?? [], id: \.commentIdentifier) { comment in
                            CommentView(comment: comment)
                        }
                        if currentItem.isFetchingComments == true {
                            LoadingView(style: .light) // fetching continuation
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            Color.clear
                                .onAppear {
                                    currentItem.fetchVideoCommentsContinuation()
                                }
                        }
                    }
                    .padding(.vertical)
                }
                .scrollContentBackground(.hidden)
            } else {
                Text("Can't load comments at the moment")
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}

struct CommentView: View {
    let comment: YTComment
    
    @State private var isExpanded: Bool = false
    @State private var textHeight: CGFloat? = nil
    
    @State private var repliesExpanded: Bool = false
    @State private var isFetchingNewReplies: Bool = false
    
    private let maxLines: Int = 5
    
    private var largeText: Bool {
        if let textHeight = self.textHeight {
            return textHeight >= UIFont.systemFont(ofSize: self.commentFontSize).lineHeight * CGFloat(self.maxLines + 1)
        } else {
            return false
        }
    }
    
    private let otherStuffThanTextHeight: CGFloat = 120
    
    private var nonExpandedBlocHeight: CGFloat {
        (self.textHeight ?? 0) + otherStuffThanTextHeight
    }
    
    private let commentFontSize: CGFloat = 14
    
    private let accessoriesColor: Color = Color(cgColor: .init(red: 0.9, green: 0.9, blue: 0.9, alpha: 1))
    
    var body: some View {
        LazyVStack {
            Group {
                HStack {
                    VStack(alignment: .leading) {
                        self.topUtilitiesView
                        Text(self.comment.text)
                            .foregroundStyle(.white)
                            .font(.system(size: self.commentFontSize))
                            .multilineTextAlignment(.leading)
                            .lineLimit(self.isExpanded ? nil : self.maxLines) // we add a "Read More button that takes one line"
                        //.frame(maxHeight: .infinity, alignment: .top)
                            .background {
                                // get size of text
                                Text(self.comment.text)
                                    .foregroundStyle(.white)
                                    .font(.system(size: self.commentFontSize))
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .overlay(
                                        GeometryReader { geometry in
                                            Color.clear
                                                .onAppear {
                                                    self.textHeight = geometry.size.height
                                                }
                                        }
                                    )
                                    .frame(height: 99999)
                                    .hidden()
                            }
                            .frame(maxHeight: self.isExpanded ? 99999 : self.textHeight)
                            .clipped()
                        self.bottomUtilitiesView
                    }
                    .clipped()
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.gray.gradient)
                    .opacity(0.5)
                RoundedRectangle(cornerRadius: 10)
                    .stroke(style: .init(lineWidth: 2))
                    .foregroundStyle(Color(cgColor: .init(red: 0.7, green: 0.7, blue: 0.7, alpha: 1)))
                    .opacity(0.5)
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, maxHeight: (self.isExpanded ? 9999 : nonExpandedBlocHeight), alignment: .top)
            
            if self.repliesExpanded {
                self.repliesView
            }
        }
        .clipped()
    }
    
    @ViewBuilder private var topUtilitiesView: some View {
        HStack {
            if let avatarURL = comment.sender?.thumbnails.last?.url {
                CachedAsyncImage(url: avatarURL, content: { phase, _ in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .clipShape(Circle())
                            .frame(width: 30, height: 30)
                    default:
                        UnknownAvatarView()
                            .scaledToFit()
                            .clipShape(Circle())
                            .frame(width: 30, height: 30)
                    }
                })
            }
            if let commentAuthorName = comment.sender?.name {
                Text(commentAuthorName + (comment.timePosted != nil ? " • \(comment.timePosted!)" : ""))
                    .bold()
                    .foregroundStyle(accessoriesColor)
                    .font(.system(size: 11))
                    .lineLimit(1)
            }
            Spacer()
            if self.largeText {
                Button {
                    withAnimation {
                        self.isExpanded.toggle()
                    }
                } label: {
                    Text(self.isExpanded ? "Read less" : "Read more")
                        .font(.system(size: 11))
                        .bold()
                        .foregroundStyle(accessoriesColor)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 5)
        .frame(maxHeight: .infinity, alignment: .top)
    }
    
    @ViewBuilder private var bottomUtilitiesView: some View {
        let displayLikeButton = comment.likesCount != nil || comment.likeState != nil || comment.actionsParams[.like] != nil
        let displayDislikeButton = comment.actionsParams[.dislike] != nil
        let displayReplyButton = comment.actionsParams[.reply] != nil || !comment.replies.isEmpty
        
        let isSomethingInThisBar = displayReplyButton || displayLikeButton || displayDislikeButton || comment.totalRepliesNumber != nil
        HStack {
            if displayLikeButton {
                Button {
                    if comment.likeState == .liked {
                        VideoPlayerModel.shared.currentItem?.commentLikeAction(.removeLike, comment: comment)
                    } else {
                        VideoPlayerModel.shared.currentItem?.commentLikeAction(.like, comment: comment)
                    }
                } label: {
                    Image(systemName: comment.likeState == .liked ? "hand.thumbsup.fill" : "hand.thumbsup")
                    if let likeCount = comment.likeState == .liked ? comment.likesCountWhenUserLiked ?? comment.likesCount : comment.likesCount {
                        Text(likeCount)
                    }
                }
                .disabled(comment.actionsParams[.like] == nil)
                .buttonStyle(.plain)
                .foregroundStyle(accessoriesColor)
            }
            if displayDislikeButton {
                Button {
                    if comment.likeState == .disliked {
                        VideoPlayerModel.shared.currentItem?.commentLikeAction(.removeDislike, comment: comment)
                    } else {
                        VideoPlayerModel.shared.currentItem?.commentLikeAction(.dislike, comment: comment)
                    }
                } label: {
                    Image(systemName: comment.likeState == .disliked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                }
                .buttonStyle(.plain)
                .padding(.leading, displayLikeButton ? nil : 0)
                .foregroundStyle(accessoriesColor)
            }
            Spacer()
            if let totalRepliesNumber = comment.totalRepliesNumber ?? (comment.replies.isEmpty ? nil : String(comment.replies.count)), !totalRepliesNumber.isEmpty {
                Button {
                    withAnimation {
                        self.repliesExpanded.toggle()
                    }
                } label: {
                    Text(totalRepliesNumber == "1" ? totalRepliesNumber + " reply" : totalRepliesNumber + " replies")
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(self.repliesExpanded ? -180 : 0))
                }
                .buttonStyle(.plain)
                .foregroundStyle(accessoriesColor)
            }
            
            // TODO: implement this button
            if displayReplyButton && false {
                Button {
                    
                } label: {
                    Image(systemName: "bubble.and.pencil")
                }
                .buttonStyle(.plain)
                .padding(.leading, displayLikeButton ? nil : 0)
                .foregroundStyle(accessoriesColor)
            }
        }
        .padding(.top, isSomethingInThisBar ? 5 : 0)
        .padding(.vertical, 3) // for the light gray stroke
        .frame(maxHeight: isSomethingInThisBar ? .infinity : 0, alignment: .bottom)
        .clipped()
    }
    
    @ViewBuilder private var repliesView: some View {
        LazyVStack {
            HStack {
                Capsule()
                    .foregroundStyle(self.accessoriesColor)
                    .frame(width: 4)
                    .opacity(self.comment.replies.isEmpty ? 0 : 0.6)
                    .padding(.leading)
                LazyVStack {
                    ForEach(self.comment.replies, id: \.commentIdentifier) { reply in
                        CommentView(comment: reply)
                    }
                }
            }
            if self.isFetchingNewReplies {
                LoadingView(style: .light)
            }
            if self.comment.actionsParams[.repliesContinuation] != nil {
                Color.clear
                    .onAppear {
                        self.isFetchingNewReplies = true
                        Task {
                            do {
                                let replies = try await self.comment.fetchRepliesContinuation(youtubeModel: YTM)
                                DispatchQueue.main.safeSync {
                                    withAnimation {
                                        self.isFetchingNewReplies = false
                                        VideoPlayerModel.shared.currentItem?.mergeRepliesToComment(self.comment.commentIdentifier, replies: replies.results, newToken: replies.continuationToken)
                                    }
                                }
                            } catch {
                                Logger.atwyLogs.simpleLog("Failed to fetch replies: \(error.localizedDescription)")
                                DispatchQueue.main.async {
                                    withAnimation {
                                        self.isFetchingNewReplies = false
                                        self.repliesExpanded = false
                                    }
                                }
                            }
                        }
                    }
            }
        }
    }
}

#Preview {
    let comments: [YTComment] = [
        .init(commentIdentifier: UUID().uuidString, sender: .init(name: "Antoine Bollengier", channelId: "", thumbnails: [.init(url: .init(string: "https://yt3.ggpht.com/8e1-6kx0mo8BRgIkkO4u7auZlaACmHyAvaEeEtl1mW6csiZtli6p-PHDi7-R5ZkT-Afr98X_=s68-c-k-c0x00ffffff-no-rj")!)]), text: "Amazing video!", replies: [
            .init(commentIdentifier: UUID().uuidString, sender: .init(name: "Antoine Bollengier", channelId: "", thumbnails: [.init(url: .init(string: "https://yt3.ggpht.com/8e1-6kx0mo8BRgIkkO4u7auZlaACmHyAvaEeEtl1mW6csiZtli6p-PHDi7-R5ZkT-Afr98X_=s68-c-k-c0x00ffffff-no-rj")!)]), text: "Amazing video!", timePosted: "2 days ago", replies: [], actionsParams: [:])
        ], actionsParams: [:]),
        .init(commentIdentifier: UUID().uuidString, sender: .init(name: "Antoine Bollengier", channelId: "", thumbnails: [.init(url: .init(string: "https://yt3.ggpht.com/8e1-6kx0mo8BRgIkkO4u7auZlaACmHyAvaEeEtl1mW6csiZtli6p-PHDi7-R5ZkT-Afr98X_=s68-c-k-c0x00ffffff-no-rj")!)]), text: "Amazing video!", timePosted: "2 days ago", replies: [], actionsParams: [:]),
        .init(commentIdentifier: UUID().uuidString, sender: .init(name: "Antoine Bollengier", channelId: "", thumbnails: [.init(url: .init(string: "https://yt3.ggpht.com/8e1-6kx0mo8BRgIkkO4u7auZlaACmHyAvaEeEtl1mW6csiZtli6p-PHDi7-R5ZkT-Afr98X_=s68-c-k-c0x00ffffff-no-rj")!)]), text: "Amazing video!", timePosted: "2 days ago",  likesCount: "1", likesCountWhenUserLiked: "2", replies: [], totalRepliesNumber: "gg",actionsParams: [.like: "test", .dislike: "test", .reply: "rep"]),
        .init(commentIdentifier: UUID().uuidString, sender: .init(name: "Antoine Bollengier", channelId: "", thumbnails: [.init(url: .init(string: "https://yt3.ggpht.com/8e1-6kx0mo8BRgIkkO4u7auZlaACmHyAvaEeEtl1mW6csiZtli6p-PHDi7-R5ZkT-Afr98X_=s68-c-k-c0x00ffffff-no-rj")!)]), text: "Amazing video!", timePosted: "2 days ago", replies: [], actionsParams: [.dislike: "test", .reply: "rep"]),
        .init(commentIdentifier: UUID().uuidString, sender: .init(name: "Antoine Bollengier", channelId: "", thumbnails: [.init(url: .init(string: "https://yt3.ggpht.com/8e1-6kx0mo8BRgIkkO4u7auZlaACmHyAvaEeEtl1mW6csiZtli6p-PHDi7-R5ZkT-Afr98X_=s68-c-k-c0x00ffffff-no-rj")!)]), text: "Amazing video! This is a very very very very very very very very very very very very very long comment",  timePosted: "2 days ago", replies: [], actionsParams: [:]),
        .init(commentIdentifier: UUID().uuidString, sender: .init(name: "Antoine Bollengier", channelId: "", thumbnails: [.init(url: .init(string: "https://yt3.ggpht.com/8e1-6kx0mo8BRgIkkO4u7auZlaACmHyAvaEeEtl1mW6csiZtli6p-PHDi7-R5ZkT-Afr98X_=s68-c-k-c0x00ffffff-no-rj")!)]), text: "Amazing video! This is a very \(Array(repeating: "very", count: 100).joined(separator: " ")) long comment", timePosted: "2 days ago", likesCount: "10", replies: [], actionsParams: [:])
    ]
    
    ScrollView {
        LazyVStack {
            ForEach(comments, id: \.commentIdentifier) { comment in
                CommentView(comment: comment)
            }
        }
        .padding()
    }
    .scrollContentBackground(.hidden)
}
