//
//  SettingsMenu.swift
//  Atwy
//
//  Created by Antoine Bollengier on 18.07.2024.
//  Copyright © 2024-2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI

struct SettingsMenu<HeaderView>: View where HeaderView: View {
    let title: String
    
    @ViewBuilder let header: (GeometryProxy) -> HeaderView
    
    @SettingsMenuBuilder let sections: (GeometryProxy) -> [SettingsSection]
    
    init(title: String, @ViewBuilder header: (@escaping (GeometryProxy) -> HeaderView), @SettingsMenuBuilder sections: @escaping (GeometryProxy) -> [SettingsSection]) {
        self.title = title
        self.header = header
        self.sections = sections
    }
    
    init(title: String, @SettingsMenuBuilder sections: @escaping (GeometryProxy) -> [SettingsSection]) where HeaderView == EmptyView {
        self.title = title
        self.header = {_ in EmptyView() }
        self.sections = sections
    }
    
    var body: some View {
        GeometryReader { geometry in
            List {
                header(geometry)
                ForEach(Array(sections(geometry).enumerated()), id: \.offset) { (_, section) in
                    section
                }
            }
        }
        .navigationTitle(title)
    }
}

#Preview {
    NavigationStack {
        SettingsMenu(title: "Account", sections: { _ in
            SettingsSection(title: "Test", settings: {
                Setting(textDescription: "Test description", action: try! SAStepper(valueType: Int.self, PSMType: .loggerCacheLimit, title: "Limit"), privateAPIWarning: true)
                Setting(textDescription: "Test description", action: try! SAStepper(valueType: Int.self, PSMType: .loggerCacheLimit, title: "Limit").step(2))
                Setting(textDescription: "Auto PiP", action: try! SAToggle(PSMType: .automaticPiP, title: "Auto PiP"))
            })
            SettingsSection(title: "Test", settings: {
                Setting(textDescription: nil, action: try! SAToggle(PSMType: .automaticPiP, title: "Auto PiP"))
                Setting(textDescription: nil, action:  SATextButton(title: "Auto PiP", buttonLabel: "Reset", action: {_ in}))
                Setting(textDescription: "This will reset your iPhone.", action:  SATextButton(title: "", buttonLabel: "Reset", action: {_ in}))            })
        })
    }
}

