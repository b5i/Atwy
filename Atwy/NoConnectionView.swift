//
//  NoConnectionView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 21.10.2023.
//

import SwiftUI

struct NoConnectionView: View {
    var body: some View {
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
    }
}
