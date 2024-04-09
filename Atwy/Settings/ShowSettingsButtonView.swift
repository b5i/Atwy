//
//  ShowSettingsButtonView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 18.11.2023.
//

import SwiftUI


struct ShowSettingsButtonView: View {
    @ObservedObject private var NRM = NetworkReachabilityModel.shared
    var body: some View {
        Button {
            SheetsModel.shared.showSheet(.settings)
        } label: {
            UserPreferenceCircleView()
                .frame(width: 40, height: 40)
        }
    }
}
