//
//  SettingsMenuBuilder.swift
//  Atwy
//
//  Created by Antoine Bollengier on 18.07.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

@resultBuilder
struct SettingsMenuBuilder {
    static func buildBlock(_ components: SettingsSection...) -> [SettingsSection] {
        return components
    }
    
    static func buildEither(first component: [SettingsSection]) -> [SettingsSection] {
        return component
    }
    
    static func buildEither(second component: [SettingsSection]) -> [SettingsSection] {
        return component
    }
}
