//
//  VideoInScrollViewCell.swift
//  Atwy
//
//  Created by Antoine Bollengier on 02.01.2026.
//  Copyright © 2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//

import UIKit
import YouTubeKit
import SwiftUI

class VideoInScrollViewCell: UITableViewCell, AnimatableCell {
    static let reuseIdentifier = "VideoInScrollViewCell"
    private var hostingController: UIHostingController<VideoInScrollView>?
    
    private var video: YTVideo? = nil

    func configure(with item: YTElementWithData, parentVC: UIViewController) {
        guard let video = item.element as? YTVideo else { return }
        self.video = video
        var newData = item.data
        newData.shouldApplyHorizontalPadding = false
        let item = YTVideoWithData(video: video, data: newData)
        let swiftUIView = VideoInScrollView(video: item, size: self.contentView.bounds.size)

        if let hostingController = self.hostingController {
            hostingController.rootView = swiftUIView
        } else {
            let newHostingController = UIHostingController(rootView: swiftUIView)
            self.hostingController = newHostingController
            
            parentVC.addChild(newHostingController)
            contentView.addSubview(newHostingController.view)
            newHostingController.view.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                newHostingController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                newHostingController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                newHostingController.view.topAnchor.constraint(equalTo: contentView.topAnchor),
                newHostingController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
            newHostingController.didMove(toParent: parentVC)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        hostingController?.willMove(toParent: nil)
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()
        hostingController = nil
        self.transform = .identity
        self.alpha = 1
        self.layer.removeAllAnimations()
    }
    
    var hasAnimated = true
        
    func animate() {
        //self.layoutIfNeeded()
        guard !hasAnimated else { return }
        hasAnimated = true
        
        self.transform = CGAffineTransform(translationX: 0, y: 180 * 0.3)
        self.alpha = 0
        //let startTime = CACurrentMediaTime()
        UIView.animate(
            withDuration: 0.3,
            delay: 0.05 * Double((video?.id ?? 0) + 1),
            options: [.curveEaseOut],
            animations: {
                self.transform = CGAffineTransform(translationX: 0, y: 0)
                self.alpha = 1
            }, completion: { state in
                //print(self.video?.id, "state is", state, "time is", CACurrentMediaTime() - startTime)
            })
    }
}
