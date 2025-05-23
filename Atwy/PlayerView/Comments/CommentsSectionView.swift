//
//  CommentsSectionView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 31.03.2025.
//  Copyright © 2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//

import SwiftUI

struct CommentsSectionView: View {
    @ObservedObject var currentItem: YTAVPlayerItem
    
    var body: some View {
        Group {
            if currentItem.isFetchingComments == true && currentItem.comments == nil {
                LoadingView(style: .light)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else if currentItem.comments == nil && currentItem.moreVideoInfos?.commentsContinuationToken != nil  {
                Color.clear
                    .onAppear {
                        currentItem.fetchVideoComments()
                    }
            } else if currentItem.comments != nil {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        GlobalCustomCommentView(postCommentToken: currentItem.comments?.commentCreationToken, addCommentAction: { newComment in
                            currentItem.addComment(newComment)
                        })
                        ForEach(currentItem.comments?.results ?? [], id: \.commentIdentifier) { comment in
                            let deleteCallback: (String) -> Void = { commentId in
                                withAnimation {
                                    self.currentItem.removeComment(withIdentifier: commentId, animated: true)
                                }
                            }
                            
                            if #available(iOS 17.0, *) {
                                CommentView(comment: comment, deleteCallback: deleteCallback)
                                    .geometryGroup() // avoid jumping comments
                            } else {
                                CommentView(comment: comment, deleteCallback: deleteCallback)
                            }
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
                .ignoresSafeArea(.keyboard, edges: .bottom)
            } else {
                Text("No comments")
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}
