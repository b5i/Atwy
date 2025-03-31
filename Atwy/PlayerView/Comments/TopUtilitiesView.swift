//
//  TopUtilitiesView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 31.03.2025.
//  Copyright © 2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI
import YouTubeKit

struct TopUtilitiesView: View {
        let comment: YTComment
        let largeText: Bool
        @Binding var isExpanded: Bool
        
        private let accessoriesColor: Color = Color(cgColor: .init(red: 0.9, green: 0.9, blue: 0.9, alpha: 1))
        var body: some View {
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
                } else {
                    UnknownAvatarView()
                        .scaledToFit()
                        .clipShape(Circle())
                        .frame(width: 30, height: 30)
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
    }
