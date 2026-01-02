//
//  NotConnectedToGoogleView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 21.10.2023.
//  Copyright © 2023-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//

import SwiftUI

struct NotConnectedToGoogleView: View {
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            Image(systemName: "person.crop.circle.fill.badge.xmark")
                .resizable()
                .scaledToFit()
                .frame(width: 150)
                .padding()
            Text("You are not connected to Google.")
                .font(.title2)
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(colors: [.blue, .purple, .blue], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 150, height: 40)
                Text("Connect")
                    .foregroundStyle(.white)
            }
            .routeTo(.googleConnection)
            .padding()
            Spacer()
        }
        .padding(.bottom)
        .routeContainer()
    }
}
