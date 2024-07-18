//
//  Setting.swift
//  Atwy
//
//  Created by Antoine Bollengier on 18.07.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI

struct Setting: View {
    let textDescription: String?
        
    let action: any SettingAction
    
    var privateAPIWarning: Bool = false
    
    var hidden: Bool = false
    
    var body: some View {
        if hidden {
            EmptyView()
        } else {
            VStack(alignment: .leading) {
                AnyView(action)
                if let textDescription = self.textDescription {
                    Text(LocalizedStringKey(textDescription))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if privateAPIWarning {
                    Label("Private APIs checks have failed for this option, therefore you can't enable it for safety reasons.", systemImage: "exclamationmark.triangle.fill")
                        .labelStyle(FailedInitPrivateAPILabelStyle())
                }
            }
            .disabled(privateAPIWarning)
        }
    }
}
