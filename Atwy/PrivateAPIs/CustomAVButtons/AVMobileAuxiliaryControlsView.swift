//
//  AVMobileAuxiliaryControlsView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 29.03.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation
import UIKit
import Combine
import YouTubeKit
import OSLog

class AVMobileAuxiliaryControlsView {    
    let manager: CustomAVButtonsManager
    
    var menuState: MenuState = .automatic
    
    var mainInstance: UIView? = nil
        
    init(manager: CustomAVButtonsManager) {
        self.manager = manager
        let handler: (@convention(block) (NSObject) -> Bool) = { [weak self] controlsView in
            let defaultStatus = controlsView.value(forKey: "_requiresOverflowControl2") as? Bool
            
            guard let self = self else { return defaultStatus ?? true }
            self.mainInstance = controlsView as? UIView
            
            switch self.menuState {
            case .alwaysVisible:
                return true
            case .hidden:
                return false
            case .automatic:
                return defaultStatus ?? true
            }
        }
         
        
        if PreferencesStorageModel.shared.customAVButtonsEnabled {
            self.injectInMethod()
        }
            
        
        let imp = imp_implementationWithBlock(unsafeBitCast(handler, to: NSObject.self))
        
        guard !manager.AVMobileAuxiliaryControlsViewClass.responds(to: NSSelectorFromString("_requiresOverflowControl2")) else {
            method_setImplementation(
                class_getInstanceMethod(
                    manager.AVMobileAuxiliaryControlsViewClass,
                    NSSelectorFromString("_requiresOverflowControl")
                )!,
                imp
            )
            return
        }
        
        class_addMethod(
            manager.AVMobileAuxiliaryControlsViewClass,
            NSSelectorFromString("_requiresOverflowControl2"),
            imp,
            method_getTypeEncoding(
                class_getInstanceMethod(
                    manager.AVMobileAuxiliaryControlsViewClass,
                    NSSelectorFromString("_requiresOverflowControl")
                )!
            )
        )
        
        method_exchangeImplementations(
            class_getInstanceMethod(
                manager.AVMobileAuxiliaryControlsViewClass,
                NSSelectorFromString("_requiresOverflowControl"))!,
            class_getInstanceMethod(
                manager.AVMobileAuxiliaryControlsViewClass,
                NSSelectorFromString("_requiresOverflowControl2"))!
        )
        
        VideoPlayerModel.shared.$currentItem.sink(receiveValue: { [weak self] newValue in
            guard let self = self, let newValue = newValue else { return }
            newValue.$moreVideoInfos.sink(receiveValue: {[weak self] newLikeStatus in
                guard let self = self, let newLikeStatus = newLikeStatus?.authenticatedInfos?.likeStatus else { return }
                self.handleNewLikeStatus(newLikeStatus)
            }).store(in: &self.subscriptions)
        }).store(in: &subscriptions)
    }
        
    private var subscriptions: Set<AnyCancellable> = Set()
    
    //private var testButtonDelegate: NSObject? = nil
    private var likeButtonControl: AVMobileAuxiliaryControl? = nil
    private var dislikeButtonControl: AVMobileAuxiliaryControl? = nil
    private var realRouteDelegate: CustomAVControlOverflowButtonDelegate? = nil
    
    private func handleNewLikeStatus(_ likeStatus: MoreVideoInfosResponse.AuthenticatedData.LikeStatus?) {
        if let likeStatus = likeStatus {
            switch likeStatus {
            case .liked:
                self.likeButtonControl?.setNewImageWithName("hand.thumbsup.fill")
                self.dislikeButtonControl?.setNewImageWithName("hand.thumbsdown")
            case .disliked:
                self.likeButtonControl?.setNewImageWithName("hand.thumbsup")
                self.dislikeButtonControl?.setNewImageWithName("hand.thumbsdown.fill")
            case .nothing:
                self.likeButtonControl?.setNewImageWithName("hand.thumbsup")
                self.dislikeButtonControl?.setNewImageWithName("hand.thumbsdown")
            }
            self.likeButtonControl?.setIncluded(true)
            self.dislikeButtonControl?.setIncluded(true)
        } else {
            self.handleNewLikeStatus(.nothing)
            self.likeButtonControl?.setIncluded(false)
            self.dislikeButtonControl?.setIncluded(false)
        }
    }
    
    private func handleControls(fullScreenState: FullScreenState, defaultControlsToAdd: [NSObject]) -> (overflowMenuItems: [UIMenuElement], overflowMenuControls: [NSObject], barItems: [NSObject]) {
        switch fullScreenState {
        case .fullScreen:
            var visibleControls: [NSObject] = []
            
            guard APIKeyModel.shared.userAccount != nil, VideoPlayerModel.shared.currentItem?.isAbleToLike == true else { fallthrough } // we don't show the like/dislike buttons if the user is not connected
            
            let likeStatus = VideoPlayerModel.shared.currentItem?.moreVideoInfos?.authenticatedInfos?.likeStatus
            
            let likeButton = AVButton(forImage: likeStatus == .liked ? "hand.thumbsup.fill" : "hand.thumbsup", action: UIAction(handler: { _ in
                if let currentStatus = VideoPlayerModel.shared.currentItem?.moreVideoInfos?.authenticatedInfos?.likeStatus {
                    if currentStatus == .liked {
                        VideoPlayerModel.shared.currentItem?.video.removeLikeFromVideo(youtubeModel: YTM, result: { error in
                            if let error = error {
                                Logger.atwyLogs.simpleLog("Error while removing like from video: \(error)")
                            } else {
                                VideoPlayerModel.shared.currentItem?.setNewLikeStatus(.nothing)
                            }
                        })
                    } else {
                        VideoPlayerModel.shared.currentItem?.video.likeVideo(youtubeModel: YTM, result: { error in
                            if let error = error {
                                Logger.atwyLogs.simpleLog("Error while liking video: \(error)")
                            } else {
                                VideoPlayerModel.shared.currentItem?.setNewLikeStatus(.liked)
                            }
                        })
                    }
                }
            }), accessibilityLabel: "Like Video", manager: self.manager)
            self.likeButtonControl = AVMobileAuxiliaryControl(button: likeButton, priority: 2, controlName: "likebutton", manager: self.manager)
            likeButtonControl!.setIncluded(likeStatus != nil)
            visibleControls.append(likeButtonControl!.control)
            
            let dislikeButton = AVButton(forImage: likeStatus == .disliked ? "hand.thumbsdown.fill" : "hand.thumbsdown", action: UIAction(handler: { _ in
                if let currentStatus = VideoPlayerModel.shared.currentItem?.moreVideoInfos?.authenticatedInfos?.likeStatus {
                    if currentStatus == .disliked {
                        VideoPlayerModel.shared.currentItem?.video.removeLikeFromVideo(youtubeModel: YTM, result: { error in
                            if let error = error {
                                Logger.atwyLogs.simpleLog("Error while removing dislike from video: \(error)")
                            } else {
                                VideoPlayerModel.shared.currentItem?.setNewLikeStatus(.nothing)
                            }
                        })
                    } else {
                        VideoPlayerModel.shared.currentItem?.video.dislikeVideo(youtubeModel: YTM, result: { error in
                            if let error = error {
                                Logger.atwyLogs.simpleLog("Error while disliking from video: \(error)")
                            } else {
                                VideoPlayerModel.shared.currentItem?.setNewLikeStatus(.disliked)
                            }
                        })
                    }
                }
            }), accessibilityLabel: "Dislike Video", manager: self.manager)
            self.dislikeButtonControl = AVMobileAuxiliaryControl(button: dislikeButton, priority: 1, controlName: "dislikebutton", manager: self.manager)
            dislikeButtonControl!.setIncluded(likeStatus != nil)
            visibleControls.append(dislikeButtonControl!.control)
            
            /*
             let testButton = AVMenuButton(forImage: "star", menu: UIMenu(title: "My testmenubutton", image: UIImage(systemName: "plus.circle"), children: [
             UIDeferredMenuElement({_ in})
             ]), buttonDisplayName: "test", buttonIdentifier: "testbutton", manager: self.manager)
             let testButtonControl = AVMobileAuxiliaryControl(button: testButton, priority: 0, controlName: "Test", manager: self.manager)
             self.testButtonDelegate = testButton.delegate
             visibleControls.append(testButtonControl.control)
             */
            
            visibleControls.append(contentsOf: (defaultControlsToAdd.filter({$0.value(forKey: "_identifier") as? String == "AVAnalysisControl"})))
            visibleControls.append(AVMobileAuxiliaryControl(priority: 0, controlName: "fakeControl", manager: self.manager).control) // create a empty control so that the controls are immediatly displayed
            
            return ([
                UIMenu(title: "", options: .displayInline, children: [ // show a divider
                    UIMenu(title: "Add To Playlist", image: UIImage(systemName: "plus.circle"), children: [
                        UIDeferredMenuElement({ result in
                            guard let video = VideoPlayerModel.shared.currentItem?.video else { result([]); return }
                            video.fetchAllPossibleHostPlaylists(youtubeModel: YTM, result: { returning in
                                switch returning {
                                case .success(let response):
                                    guard !response.isDisconnected else { fallthrough }
                                    DispatchQueue.main.async {
                                        result(response.playlistsAndStatus.map({ playlistAndStatus in
                                            return UIAction(
                                                title: playlistAndStatus.playlist.title ?? "Unknown name",
                                                image: UIImage(systemName: PrivacyIconView.getIconNameForPrivacyType(playlistAndStatus.playlist.privacy ?? .unlisted)),
                                                state: playlistAndStatus.isVideoPresentInside ? .on : .off,
                                                handler: { _ in
                                                    if playlistAndStatus.isVideoPresentInside {
                                                        RemoveVideoByIdFromPlaylistResponse.sendNonThrowingRequest(youtubeModel: YTM, data: [.movingVideoId: video.videoId, .browseId: playlistAndStatus.playlist.playlistId], result: {_ in})
                                                    } else {
                                                        AddVideoToPlaylistResponse.sendNonThrowingRequest(youtubeModel: YTM, data: [.movingVideoId: video.videoId, .browseId: playlistAndStatus.playlist.playlistId], result: { _ in })
                                                    }
                                                })
                                        }))
                                    }
                                case .failure(_):
                                    DispatchQueue.main.async {
                                        result([])
                                    }
                                }
                            })
                        })
                    ]),
                    UIAction(title: "Share", image: UIImage(systemName: "square.and.arrow.up"), handler: { _ in
                        VideoPlayerModel.shared.currentItem?.video.showShareSheet()
                    })
                ])], defaultControlsToAdd, visibleControls)
        case .notFullScreen:
            return ([], [], defaultControlsToAdd)
        }
    }
    
    func injectInMethod() {
        let handler: (@convention(block) (NSObject, [NSObject]) -> Void) = { [weak self] controlsView, controlsToAdd in
            guard let self = self else { controlsView.perform(NSSelectorFromString("setControls2:"), with: controlsToAdd); return }
            self.mainInstance = controlsView as? UIView
            let fullScreenState = FullScreenState(rawValue: (controlsView.value(forKeyPath: "_delegate._fullscreenController.presentationState") as? Int ?? 0)) ?? .notFullScreen
        
            let (menuItems, menuControls, visibleControls) = self.handleControls(fullScreenState: fullScreenState, defaultControlsToAdd: controlsToAdd)
            
            
            self.realRouteDelegate = CustomAVControlOverflowButtonDelegate(addedItems: menuControls, actions: menuItems, globalDelegate: controlsView, manager: self.manager)
            
            (controlsView.value(forKey: "_overflowControl") as? NSObject)?.perform(NSSelectorFromString("setDelegate:"), with: realRouteDelegate)
            
            controlsView.perform(NSSelectorFromString("setControls2:"), with: visibleControls)
        }
        
        let imp = imp_implementationWithBlock(unsafeBitCast(handler, to: NSObject.self))
        
        guard !self.manager.AVMobileAuxiliaryControlsViewClass.responds(to: NSSelectorFromString("setControls2:")) else {
            if PreferencesStorageModel.shared.customAVButtonsEnabled {
                method_setImplementation(
                    class_getInstanceMethod(
                        self.manager.AVMobileAuxiliaryControlsViewClass,
                        NSSelectorFromString("setControls2:")
                    )!,
                    imp
                )
                method_exchangeImplementations(
                    class_getInstanceMethod(
                        self.manager.AVMobileAuxiliaryControlsViewClass,
                        NSSelectorFromString("setControls:"))!,
                    class_getInstanceMethod(
                        self.manager.AVMobileAuxiliaryControlsViewClass,
                        NSSelectorFromString("setControls2:"))!
                )
                DispatchQueue.main.async {
                    PreferencesStorageModel.shared.setNewValueForKey(.customAVButtonsEnabled, value: true)
                }
            } else { // just a new implementation
                method_setImplementation(
                    class_getInstanceMethod(
                        self.manager.AVMobileAuxiliaryControlsViewClass,
                        NSSelectorFromString("setControls:")
                    )!,
                    imp
                )
            }
            return
        }
                    
        class_addMethod(
            self.manager.AVMobileAuxiliaryControlsViewClass,
            NSSelectorFromString("setControls2:"),
            imp,
            method_getTypeEncoding(
                class_getInstanceMethod(
                    self.manager.AVMobileAuxiliaryControlsViewClass,
                    NSSelectorFromString("setControls:")
                )!
            )
        )
        
        method_exchangeImplementations(
            class_getInstanceMethod(
                self.manager.AVMobileAuxiliaryControlsViewClass,
                NSSelectorFromString("setControls:"))!,
            class_getInstanceMethod(
                self.manager.AVMobileAuxiliaryControlsViewClass,
                NSSelectorFromString("setControls2:"))!
        )
        
        DispatchQueue.main.async {
            PreferencesStorageModel.shared.setNewValueForKey(.customAVButtonsEnabled, value: true)
        }
    }
    
    func removeInjection() {
        guard PreferencesStorageModel.shared.customAVButtonsEnabled else { return }
        
        guard !self.manager.AVMobileAuxiliaryControlsViewClass.responds(to: NSSelectorFromString("setControls2:")) else { return } // not injected
        
        DispatchQueue.main.sync {
            PreferencesStorageModel.shared.setNewValueForKey(.customAVButtonsEnabled, value: false)
        } // we call it before in case the app crashes when calling method_exchangeImplementations and the user wouldn't be able to change the parameter
        
        method_exchangeImplementations(
            class_getInstanceMethod(
                self.manager.AVMobileAuxiliaryControlsViewClass,
                NSSelectorFromString("setControls:"))!,
            class_getInstanceMethod(
                self.manager.AVMobileAuxiliaryControlsViewClass,
                NSSelectorFromString("setControls2:"))!
        )
    }
    
    enum MenuState {
        case alwaysVisible
        case hidden
        case automatic
    }
    
    enum FullScreenState: Int {
        case notFullScreen = 2
        case fullScreen = 0
    }
}
