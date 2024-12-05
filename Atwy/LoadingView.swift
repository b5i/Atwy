//
//  LoadingView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 22.01.23.
//

import SwiftUI

struct LoadingView: View {
    var customText: String? = nil
    var body: some View {
        VStack {
            ProgressView()
                .foregroundColor(.gray)
                .padding(.bottom, 0.3)
            Text("LOADING" + ((customText == nil) ? "" : " ") + (customText?.uppercased() ?? "") + "...")
                .foregroundColor(.gray)
                .font(.caption2)
        }
        .frame(width: 160, height: 50)
    }
}
