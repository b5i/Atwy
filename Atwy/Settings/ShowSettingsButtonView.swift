//
//  ShowSettingsButtonView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 18.11.2023.
//  Copyright © 2023-2026 Antoine Bollengier. All rights reserved.
//

import SwiftUI


struct ShowSettingsButtonView: View {
    var body: some View {
        Button {
            SheetsModel.shared.showSheet(.settings)
        } label: {
            UserPreferenceCircleView()
                .frame(width: 40, height: 40)
        }
    }
}
