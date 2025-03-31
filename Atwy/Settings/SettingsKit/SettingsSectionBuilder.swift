//
//  SettingsSectionBuilder.swift
//  Atwy
//
//  Created by Antoine Bollengier on 18.07.2024.
//  Copyright © 2024-2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//

@resultBuilder
struct SettingsSectionBuilder {
    static func buildBlock(_ components: Setting...) -> [Setting] {
        return components
    }
    
    static func buildEither(first component: [Setting]) -> [Setting] {
        return component
    }
    
    static func buildEither(second component: [Setting]) -> [Setting] {
        return component
    }
}
