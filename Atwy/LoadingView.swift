//
//  LoadingView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 22.01.23.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .foregroundColor(.gray)
                .padding(.bottom, 0.3)
            Text("LOADING")
                .foregroundColor(.gray)
                .font(.caption2)
        }
        .frame(width: 150, height: 50)
    }
}
