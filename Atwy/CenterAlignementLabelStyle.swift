//
//  CenterAlignementLabelStyle.swift
//  Atwy
//
//  Created by Antoine Bollengier on 09.04.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation
import SwiftUI

struct FailedInitPrivateAPILabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center) {
            configuration.icon
            configuration.title
                .font(.caption)
        }
        .foregroundStyle(.red)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
