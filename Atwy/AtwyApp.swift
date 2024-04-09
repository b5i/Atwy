//
//  AtwyApp.swift
//  Atwy
//
//  Created by Antoine Bollengier on 19.11.22.
//

import SwiftUI
import CoreSpotlight
import YouTubeKit
import AVFoundation
import BackgroundTasks
import ActivityKit

class NavigationPathModel: ObservableObject {
    @Published var path = NavigationPath()
}

let navigationPathModel = NavigationPathModel()

func makeAVButton(forImage imageSymbolName: String, action: UIAction, accessibilityLabel: String /* we could also have an identifier for it*/) -> UIButton {
    let specialInit = (@convention(c) (NSObject.Type, Selector, NSString, NSString, Bool) -> NSObject).self
    let selector = NSSelectorFromString("buttonWithAccessibilityIdentifier:accessibilityLabel:isSecondGeneration:")
    let implementation = NSClassFromString("AVButton")!.method(for: selector)
    let method = unsafeBitCast(implementation, to: specialInit)
    let result = method(NSClassFromString("AVButton")! as! NSObject.Type, selector, accessibilityLabel as NSString, accessibilityLabel as NSString, true) as! UIButton
    
    
    
    let image = UIImage(systemName: imageSymbolName)!
    let imageView = UIImageView(image: image)
    imageView.tintColor = .white
    
    result.frame = .init(x: 0, y: 0, width: 30, height: 30)
    result.perform(NSSelectorFromString("setImage:forState:"), with: image, with: UIControl.State.normal) // AVButton
    result.perform(NSSelectorFromString("setImageName:"), with: imageSymbolName) // AVButton
    result.setValue(imageView, forKeyPath: "_visualProvider._imageView")
    result.addSubview(imageView)
    
    
    result.addAction(action, for: .touchUpInside)
    
    return result
}

func makeControlForAVButton(button: UIButton?, priority: UInt, controlName: String) -> NSObject {
    if let button = button {
        
        let specialInit2 = (@convention(c) (NSObject.Type, Selector, UIView, UInt, NSString) -> NSObject).self
        let selector2 = NSSelectorFromString("controlWithView:displayPriority:identifier:")
        let implementation2 = NSClassFromString("AVMobileAuxiliaryControl")!.method(for: selector2)
        let method2 = unsafeBitCast(implementation2, to: specialInit2)
        let toReturn = method2(NSClassFromString("AVMobileAuxiliaryControl")! as! NSObject.Type, selector2, button, priority, controlName as NSString)
         toReturn.perform(NSSelectorFromString("setIncluded:"), with: true)
        
        return toReturn
    } else {
        
        let specialInit2 = (@convention(c) (NSObject.Type, Selector, UInt, NSString) -> NSObject).self
        let selector2 = NSSelectorFromString("controlWithDisplayPriority:identifier:")
        let implementation2 = NSClassFromString("AVMobileAuxiliaryControl")!.method(for: selector2)
        let method2 = unsafeBitCast(implementation2, to: specialInit2)
        let toReturn = method2(NSClassFromString("AVMobileAuxiliaryControl")! as! NSObject.Type, selector2, priority, controlName as NSString)
        toReturn.perform(NSSelectorFromString("setIncluded:"), with: true)

        return toReturn
    }
}
func getMethodsForProtocolWithName(_ name: String) -> [(Selector, arguments: UnsafeMutablePointer<CChar>, textDescription: String)] {
    guard let protocolToUse = objc_getProtocol(name) else { return [] }
    
    let runtime = dlopen(nil, RTLD_NOW)
    let _protocol_getMethodTypeEncodingPtr = dlsym(runtime, "_protocol_getMethodTypeEncoding")
    let _protocol_getMethodTypeEncoding = unsafeBitCast(_protocol_getMethodTypeEncodingPtr, to: (@convention(c) (Protocol, Selector, Bool, Bool) -> UnsafePointer<Int8>?).self)

    var toReturn: [(Selector, arguments: UnsafeMutablePointer<CChar>, textDescription: String)] = []
    var methodCount: [UInt32] = [1]
    methodCount.withUnsafeMutableBytes { methodCountPtr in
        let castedPtr = methodCountPtr.assumingMemoryBound(to: UInt32.self).baseAddress!
        if let methodList = protocol_copyMethodDescriptionList(protocolToUse, true, true, castedPtr) {
            for i in 0..<Int(castedPtr.pointee) {
                let methodDesc = methodList[i];
                let name = methodDesc.name
                
                let result = _protocol_getMethodTypeEncoding(protocolToUse, name!, true, true)
                
                toReturn.append((methodDesc.name!, methodDesc.types!, String(cString: result!)))
            }
        }
    }
    dlclose(runtime)
    return toReturn
}

class AVControlOverflowButtonDelegateInstance: NSObject {
    var addedItems: [NSObject] // maybe just swizzle the method and those items on top of the others
    /// an array of UIMenu or UIAction (mixed or not) that will be added to the menu of the overflow button
    var actions: [NSObject]
    var globalDelegate: NSObject
    init(addedItems: [NSObject], actions: [NSObject], globalDelegate: NSObject) {
        self.addedItems = addedItems
        self.actions = actions
        self.globalDelegate = globalDelegate
        if !class_conformsToProtocol(Self.self, objc_getProtocol("AVControlOverflowButtonDelegate")) {
            makeAVControlOverflowButtonDelegateInstanceConform()
        }
    }
    
    var addedItemsButtons: [NSObject] {
        var toReturn: [NSObject] = []
        for button in self.addedItems.compactMap({$0.value(forKey: "_controlView") as? NSObject}) {
            if String(cString: object_getClassName(button)) == "AVMenuButton" {
                guard let buttonDelegate = button.value(forKey: "delegate") as? NSObject else { continue }
                toReturn.append(UIDeferredMenuElement.uncached({ provider in
                    guard let rawMenu = buttonDelegate.perform(NSSelectorFromString("menuForMenuButton:"), with: button), let menu = rawMenu.takeUnretainedValue() as? UIMenu else { provider([]); return}
                    provider([menu])
                }))
            } else {
                guard let action = (button.value(forKey: "_targetActions") as? [NSObject])?.first?.value(forKey: "_actionHandler") as? UIAction else { continue }
                let newAction = UIAction(handler: {_ in})
                newAction.setValue(action.value(forKey: "_handler"), forKey: "_handler")
                newAction.title = (button.value(forKey: "_accessibilityLabelOverride") as? String) ?? ""
                newAction.image = (button as! UIButton).currentImage
                toReturn.append(newAction)
            }
        }
        toReturn.append(contentsOf: self.actions)
        
        return toReturn
    }
}

func makeAVControlOverflowButtonDelegateInstanceConform() {
    for (selector, args, _) in getMethodsForProtocolWithName("AVControlOverflowButtonDelegate") {
        
        if selector.description.contains("overflowMenuItemsForControlOverflowButton") {
            let handler: (@convention(block) (AVControlOverflowButtonDelegateInstance, UIButton) -> [NSObject]) = { delegate, _ in
                
                var defaultItems = delegate.globalDelegate.perform(NSSelectorFromString("overflowMenuItemsForControlOverflowButton:"), with: delegate.globalDelegate.value(forKey: "_overflowControl"))
                if defaultItems != nil {
                    var castedDefaultItems: [NSObject] = (defaultItems?.takeUnretainedValue() as? [NSObject]) ?? []
                    castedDefaultItems.append(contentsOf: delegate.addedItemsButtons)
                    return castedDefaultItems
                } else {
                    return delegate.addedItemsButtons
                }
            }

            let imp = imp_implementationWithBlock(unsafeBitCast(handler, to: AVControlOverflowButtonDelegateInstance.self))
            
            class_addMethod(AVControlOverflowButtonDelegateInstance.self, selector, imp, args)
        }
    }
    class_addProtocol(AVControlOverflowButtonDelegateInstance.self, objc_getProtocol("AVControlOverflowButtonDelegate")!)
}

var realRouteDelegate: AVControlOverflowButtonDelegateInstance? = nil
func injectInMethod() {
    let handler: (@convention(block) (NSObject, [NSObject]) -> Void) = { controlsView, controlsToAdd in
        guard (controlsView.value(forKeyPath: "_delegate._fullscreenController.presentationState") as? Int) ?? 2 != 2 else { // not in fullscreenmode, 0: fullscreen, 1: fullscreen but vertical, 2: not fullscreen at all
            controlsView.perform(NSSelectorFromString("setControls2:"), with: controlsToAdd) // we basically do nothing here
            return
        }
        
        let likeButton = makeAVButton(forImage: "hand.thumbsup.fill", action: UIAction(handler: { _ in
            print("clicked djo")
        }), accessibilityLabel: "Like Video")
        let likeButtonControl = makeControlForAVButton(button: likeButton, priority: 2, controlName: "likebutton")
        
        let dislikeButton = makeAVButton(forImage: "hand.thumbsdown", action: UIAction(handler: { _ in
            print("clicked djo")
        }), accessibilityLabel: "Dislike Video")
        let dislikeButtonControl = makeControlForAVButton(button: dislikeButton, priority: 1, controlName: "dislikebutton")
        
        realRouteDelegate = AVControlOverflowButtonDelegateInstance(addedItems: controlsToAdd, actions: [UIMenu(title: "Add To Playlist", image: UIImage(systemName: "plus.circle"), children: [
            UIDeferredMenuElement({_ in})
        ])], globalDelegate: controlsView)
        
        (controlsView.value(forKey: "_overflowControl") as? NSObject)?.perform(NSSelectorFromString("setDelegate:"), with: realRouteDelegate)
        var visibleControls = [likeButtonControl, dislikeButtonControl]
        
        visibleControls.append(contentsOf: (controlsToAdd.filter({$0.value(forKey: "_identifier") as? String == "AVAnalysisControl"})))
        visibleControls.append(makeControlForAVButton(button: nil, priority: 0, controlName: "fakeControl")) // create a empty control so that the controls are immediatly displayed
        
        controlsView.perform(NSSelectorFromString("setControls2:"), with: visibleControls)
    }
    
    let imp = imp_implementationWithBlock(unsafeBitCast(handler, to: NSObject.self))
    
    class_addMethod(
        NSClassFromString("AVMobileAuxiliaryControlsView")!,
        NSSelectorFromString("setControls2:"),
        imp,
        method_getTypeEncoding(
            class_getInstanceMethod(
                NSClassFromString("AVMobileAuxiliaryControlsView")!,
                NSSelectorFromString("setControls:")
            )!
        )
    )
    
    method_exchangeImplementations(
        class_getInstanceMethod(
            NSClassFromString("AVMobileAuxiliaryControlsView")!,
            NSSelectorFromString("setControls:"))!,
        class_getInstanceMethod(
            NSClassFromString("AVMobileAuxiliaryControlsView")!,
            NSSelectorFromString("setControls2:"))!
    )
}

@main
struct AtwyApp: App {
    @State private var showChannelPopup: Bool = false
    @State private var currentChannel: String?
    @State private var isCleaningFiles: Bool = false
    @ObservedObject private var FMM = FileManagerModel.shared
    init() {
        if #available(iOS 16.1, *) {
            DownloadingsProgressActivity.registerTask()
        }
        //injectInMethod()
        Task {
            FileManagerModel.shared.fetchNewDownloadedVideosPaths()
        }
        if YTM.logger == nil {
            YTM.logger = YouTubeModelLogger.shared
        }
        
    }
    var body: some Scene {
        WindowGroup {
            Group {
                if !FMM.filesRemovedProgress {
                    VStack {
                        Text("Cleaning files...")
                            .font(.title2)
                            .bold()
                        Text("Do not close the app ")
                            .font(.caption)
                        ProgressView()
                            .padding(.top, 50)
                    }
                } else {
                    ContentView()
                        .environment(\.managedObjectContext, PersistenceModel.shared.context)
                        .onOpenURL(perform: { url in
                            print(url)
                            if url.scheme == "atwy" || url.scheme == "Atwy" {
                                switch url.host {
                                case "watch":
                                    if let videoId = url.query?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
                                        //                                Atwy://watch?_u4GmLb_NCo
                                        if videoId.count == 11 {
                                            print("received valid id")
                                            VideoPlayerModel.shared.loadVideo(video: YTVideo(videoId: videoId))
                                            SheetsModel.shared.showSheet(.watchVideo)
                                        }
                                    }
                                case "channel":
                                    if let channelID = url.query?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
                                        //                                Atwy://watch?_u4GmLb_NCo
                                        if channelID.count > 2 {
                                            print("received valid id")
                                            currentChannel = channelID
                                            showChannelPopup = true
                                        }
                                    }
                                default:
                                    break
                                }
                            }
                        })
                        .onAppear {
#if !os(macOS)
                            let appearance = UINavigationBarAppearance()
                            appearance.configureWithDefaultBackground()
                            UINavigationBar.appearance().scrollEdgeAppearance = appearance
#endif
                        }
                }
            }
            .onContinueUserActivity(CSSearchableItemActionType, perform: handleSpotlightOpening)
        }
    }
    
    private func handleSpotlightOpening(_ userActivity: NSUserActivity) {
        guard let itemAny = userActivity.userInfo?[CSSearchableItemActivityIdentifier], let itemPath =  itemAny as? String, let itemURL = URL(string: itemPath), let objectID = PersistenceModel.shared.controller.container.persistentStoreCoordinator.managedObjectID(forURIRepresentation: itemURL) else { return }
        
        let coreDataItem = PersistenceModel.shared.context.object(with: objectID)
        
        switch coreDataItem {
        case is DownloadedVideo:
            guard let video = coreDataItem as? DownloadedVideo else { break }
            loadVideoAndOpenSheet(video: video.toYTVideo(), videoThumbnailData: video.thumbnail, channelAvatarThumbnailData: video.channel?.thumbnail)
        case is FavoriteVideo:
            guard let video = coreDataItem as? FavoriteVideo, NetworkReachabilityModel.shared.connected || (PersistenceModel.shared.getDownloadedVideo(videoId: video.videoId) != nil) else { break }
            loadVideoAndOpenSheet(video: video.toYTVideo(), videoThumbnailData: video.thumbnailData, channelAvatarThumbnailData: video.channel?.thumbnail)
        case is DownloadedVideoChapter:
            guard let chapter = coreDataItem as? DownloadedVideoChapter, let video = chapter.video else { return }
            loadVideoAndOpenSheet(video: video.toYTVideo(), videoThumbnailData: video.thumbnail, channelAvatarThumbnailData: video.channel?.thumbnail, seekTo: Double(chapter.startTimeSeconds))
        default:
            break
        }
        
        func loadVideoAndOpenSheet(video: YTVideo, videoThumbnailData: Data? = nil, channelAvatarThumbnailData: Data? = nil, seekTo: Double? = nil) {
            if VideoPlayerModel.shared.currentItem?.videoId != video.videoId {
                VideoPlayerModel.shared.loadVideo(video: video, thumbnailData: videoThumbnailData, channelAvatarImageData: channelAvatarThumbnailData, seekTo: seekTo)
            } else if let seekTo = seekTo, !VideoPlayerModel.shared.isLoadingVideo {
                VideoPlayerModel.shared.player.seek(to: CMTime(seconds: seekTo, preferredTimescale: 600))
            }
            SheetsModel.shared.showSheet(.watchVideo)
        }
    }
}
