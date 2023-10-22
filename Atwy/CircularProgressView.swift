//
//  CircularProgressView.swift
//  SongLoader
//
//  Created by Antoine Bollengier on 13.08.22.
//
// FROM: https://sarunw.com/posts/swiftui-circular-progress-bar/

import SwiftUI

struct CircularProgressView: View {
    @Environment(\.colorScheme) private var colorScheme
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    colorScheme.textColor.opacity(0.3),
                    lineWidth: 3
                )
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    colorScheme.textColor.opacity(0.8),
                    style: StrokeStyle(
                        lineWidth: 3,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                // 1
                .animation(.easeOut, value: progress)

        }
    }
}
