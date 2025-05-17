//
//  GlobalCustomCommentView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 31.03.2025.
//  Copyright © 2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI
import YouTubeKit

struct GlobalCustomCommentView: View {
    let postCommentToken: String?
    let addCommentAction: (YTComment) -> Void
    
    @State private var commentText: String = ""
    @State private var isSubmittingReply: Bool = false
    
    @FocusState private var isFocused: Bool
    
    @ObservedObject private var APIM = APIKeyModel.shared
    private let accessoriesColor: Color = Color(cgColor: .init(red: 0.9, green: 0.9, blue: 0.9, alpha: 1))
    var body: some View {
        CommentBoxView(content: {
            let username = APIM.userAccount?.channelHandle
            TopUtilitiesView(comment: .init(commentIdentifier: "", sender: .init(name: username ?? "You", channelId: "", thumbnails: APIM.userAccount?.avatar ?? []), text: "", replies: [], actionsParams: [:]), largeText: false, isExpanded: .constant(false))
            CommentTextField(replyText: $commentText, replyTextSize: .constant(nil), isFocused: $isFocused)
            HStack(spacing: 20) {
                if isFocused {
                    Button {
                        self.isFocused = false
                    } label: {
                        Image(systemName: "multiply")
                    }
                    .buttonStyle(.plain)
                }
                Button {
                    self.isFocused = false
                    guard let postCommentToken = postCommentToken else { return }
                    
                    withAnimation {
                        self.isSubmittingReply = true
                    }
                    Task {
                        do {
                            let result = try await CreateCommentResponse.sendThrowingRequest(youtubeModel: YTM, data: [.params: postCommentToken, .text: commentText])
                            guard result.success, let newComment = result.newComment else { return }
                            DispatchQueue.main.safeSync {
                                self.commentText = ""
                                withAnimation {
                                    self.addCommentAction(newComment)
                                }
                            }
                        } catch {}
                        
                        DispatchQueue.main.async {
                            withAnimation {
                                self.isSubmittingReply = false
                                self.commentText = ""
                            }
                        }
                    }
                } label: {
                    if self.isSubmittingReply {
                        ProgressView()
                            .tint(self.accessoriesColor)
                    } else {
                        Image(systemName: "paperplane")
                    }
                }
                .buttonStyle(.plain)
                .disabled(commentText.isEmpty)
            }
            .animation(.spring(duration: 0.1), value: self.isFocused)
            .padding(.leading)
            .foregroundStyle(accessoriesColor)
            .padding(.top, 10)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }, shouldPadTrailing: true)
        .disabled(APIM.userAccount == nil || postCommentToken == nil)
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    GlobalCustomCommentView(postCommentToken: "", addCommentAction: {_ in})
}
