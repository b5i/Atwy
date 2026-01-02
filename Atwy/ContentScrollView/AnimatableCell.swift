//
//  AnimatableCell.swift
//  Atwy
//
//  Created by Antoine Bollengier on 02.01.2026.
//  Copyright © 2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//

import UIKit

protocol AnimatableCell: UITableViewCell {
    var hasAnimated: Bool { get set }
    func animate()
}
