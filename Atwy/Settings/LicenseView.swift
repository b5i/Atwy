//
//  LicenseView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 04.12.2023.
//  Copyright © 2023-2026 Antoine Bollengier. All rights reserved.
//

import SwiftUI

public struct LicenseView: View {
    let license: License
    public var body: some View {
        VStack {
            HStack {
                Spacer()
                Link(destination: license.link, label: {
                    HStack {
                        Text("Open in GitHub")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .foregroundStyle(.green)
                    .padding(.top)
                    .padding(.horizontal, 100)
                })
                Spacer()
            }
            ScrollView {
                Text(license.content)
            }
            .padding([.horizontal, .bottom])
        }
    }
    
    public struct License: Hashable {
        var name: String
        var comment: String = ""
        var content: String
        var isSelf: Bool
        var link: URL
    }
}
