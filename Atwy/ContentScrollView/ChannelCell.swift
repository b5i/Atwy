//
//  ChannelCell.swift
//  Atwy
//
//  Created by Antoine Bollengier on 02.01.2026.
//  Copyright © 2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import UIKit
import YouTubeKit
import SwiftUI

class ChannelCell: UITableViewCell, AnimatableCell {
    static let reuseIdentifier = "ChannelCell"
    
    private var channel: YTChannel? = nil
    
    func configure(with channel: YTChannel) {
        self.channel = channel
        var content = self.defaultContentConfiguration()
        content.image = UIImage(systemName: "person.crop.rectangle.fill")
        content.text = channel.name
        content.secondaryText = "\(channel.subscriberCount) subscribers"
        self.contentConfiguration = content
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.transform = .identity
        self.alpha = 1
        self.layer.removeAllAnimations()
    }
    
    var hasAnimated = true
    
    func animate() {
        super.layoutIfNeeded()
        guard !hasAnimated else { return }
        hasAnimated = true
        
        self.transform = CGAffineTransform(translationX: 0, y: 180 * 0.3)
        self.alpha = 0
        let startTime = CACurrentMediaTime()
        UIView.animate(
            withDuration: 0.3,
            delay: 0.05 * Double((channel?.id ?? 0) + 1),
            options: [.curveEaseOut],
            animations: {
                self.transform = CGAffineTransform(translationX: 0, y: 0)
                self.alpha = 1
            }, completion: { state in
                //print(self.channel?.id, "state is", state, "time is", CACurrentMediaTime() - startTime)
            })
    }
}


