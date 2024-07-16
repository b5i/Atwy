//
//  NoConnectionView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 21.10.2023.
//

import SwiftUI

struct NoConnectionView: View {
    let menuName: String
    var body: some View {
        NavigationStack {
            VStack(alignment: .center) {
                Spacer()
                Image(systemName: "wifi.slash")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150)
                    .padding()
                Text("You are disconnected.")
                    .font(.title2)
                Text("Disable the plane mode or connect to a WiFi.")
                    .foregroundStyle(.gray)
                    .padding(.bottom)
                Spacer()
            }
            .padding(.bottom)
            .navigationTitle(menuName)
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.clear, for: .navigationBar)
            .customNavigationTitleWithRightIcon {
                ShowSettingsButtonView()
            }
        }
    }
}

#Preview {
    NoConnectionView(menuName: "Home")
}
