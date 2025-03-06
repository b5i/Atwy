//
//  PlayerBottomBarView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 06.03.2025.
//  Copyright © 2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI

struct PlayerBottomBarView: View {
    @Binding var showDescription: Bool
    @Binding var showComments: Bool
    @Binding var showQueue: Bool
    
    @ObservedObject private var VPM = VideoPlayerModel.shared
    var body: some View {
        HStack {
            let hasDescription = VPM.currentItem?.videoDescription ?? "" != ""
            let canLoadComments = VPM.currentItem?.moreVideoInfos != nil
            Spacer()
            Button {
                withAnimation(.interpolatingSpring(duration: 0.3)) {
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
                withAnimation(.interpolatingSpring(duration: 0.3)) {
                    showComments.toggle()
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .foregroundStyle(showComments ? Color(uiColor: UIColor.lightGray) : .clear)
                        .animation(nil, value: 0)
                    Image(systemName: "ellipsis.bubble")
                        .resizable()
                        .foregroundStyle(showComments ? .white : Color(uiColor: UIColor.lightGray))
                        .scaledToFit()
                        .frame(width: showComments ? 21 : 24)
                        .blendMode(showComments ? .exclusion : .screen)
                }
                .frame(width: 30, height: 30)
            }
            .opacity(canLoadComments ? 1 : 0.5)
            .disabled(!canLoadComments)
            //.opacity(hasDescription ? 1 : 0.5)
            //.disabled(!hasDescription)
            /*
             AirPlayButton()
             .scaledToFit()
             .blendMode(.screen)
             .frame(width: 50)
             */
            Spacer()
            Button {
                withAnimation(.interpolatingSpring(duration: 0.3)) {
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
            // TODO: disable the button is the queue is empty
            //.opacity(isQueueEmpty ? 1 : 0.5)
            //.disabled(!isQueueEmpty)
            Spacer()
        }
        .padding(.vertical)
        .background {
            VariableBlurView(orientation: .bottomToTop)
                .ignoresSafeArea()
        }
    }
}

