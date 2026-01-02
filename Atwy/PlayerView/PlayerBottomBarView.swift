//
//  PlayerBottomBarView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 06.03.2025.
//  Copyright © 2025-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//

import Combine
import SwiftUI

struct PlayerBottomBarView: View {
    @Binding var showDescription: Bool
    @Binding var showComments: Bool
    @Binding var showQueue: Bool
    
    @StateObject private var model = Model.shared
    
    var body: some View {
        HStack {
            Spacer()
            Button {
                withAnimation(.interpolatingSpring(duration: 0.3)) {
                    showDescription.toggle()
                    if showDescription {
                        showComments = false
                        showQueue = false
                    }
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
            .opacity(model.descriptionButtonEnabled ? 1 : 0.5)
            .disabled(!model.descriptionButtonEnabled)
            Spacer()
            Button {
                withAnimation(.interpolatingSpring(duration: 0.3)) {
                    showComments.toggle()
                    if showComments {
                        showDescription = false
                        showQueue = false
                    }
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
            .opacity(model.commentsButtonEnabled ? 1 : 0.5)
            .disabled(!model.commentsButtonEnabled)
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
                    if showQueue {
                        showDescription = false
                        showComments = false
                    }
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
            .opacity(model.queueButtonEnabled ? 1 : 0.5)
            .disabled(!model.queueButtonEnabled)
            Spacer()
        }
        .padding(.vertical)
        .background {
            VariableBlurView(orientation: .bottomToTop)
                .ignoresSafeArea()
        }
    }
    
    class Model: ObservableObject {
        static let shared = Model()
        
        @Published fileprivate(set) var descriptionButtonEnabled: Bool
        @Published fileprivate(set) var queueButtonEnabled: Bool = true
        @Published fileprivate(set) var commentsButtonEnabled: Bool
        private var observers: Set<AnyCancellable> = .init()
        private var removableObservers: Set<AnyCancellable> = .init()
        
        init() {
            self.descriptionButtonEnabled = Self.descriptionButtonEnabledFor(VideoPlayerModel.shared.currentItem?.videoDescription)
            //self.queueButtonEnabled = Self.queueButtonEnabledForQueueCount(VideoPlayerModel.shared.player.items().count)
            self.commentsButtonEnabled = VideoPlayerModel.shared.currentItem?.moreVideoInfos != nil
            
            VideoPlayerModel.shared.publisher(for: \.currentItem)
                .sink { [weak self] newValue in
                    guard let self = self else { return }
                    self.setNewObservers(forItem: newValue)
                }
                .store(in: &observers)
        }
        
        private func setNewObservers(forItem item: YTAVPlayerItem?) {
            self.removableObservers.removeAll(keepingCapacity: true)
            
            guard let item = item else {
                self.commentsButtonEnabled = false
                self.descriptionButtonEnabled = false
                return
            }
            
            item.videoDescription.publisher
                .sink { [weak self] newValue in
                    guard let self = self else { return }
                    let newFinalValue = Self.descriptionButtonEnabledFor(newValue)
                    if newFinalValue != self.descriptionButtonEnabled {
                        DispatchQueue.main.async {
                            self.descriptionButtonEnabled = newFinalValue
                        }
                    }
                }
                .store(in: &removableObservers)
            
            item.$moreVideoInfos
                .sink { [weak self] newValue in
                    guard let self = self else { return }
                    let newFinalValue = newValue != nil
                    if newFinalValue != self.commentsButtonEnabled {
                        DispatchQueue.main.async {
                            self.commentsButtonEnabled = newFinalValue
                        }
                    }
                }
                .store(in: &removableObservers)
        }
        
        private static func descriptionButtonEnabledFor(_ value: String?) -> Bool {
            return value ?? "" != ""
        }
        
        private static func queueButtonEnabledForQueueCount(_ value: Int) -> Bool {
            return value > 0
        }
    }
}

