//
//  MainTabViewModel.swift
//  Atwy
//
//  Created by Antoine Bollengier on 04.12.2023.
//

import Foundation

public class MainTabViewModel: ObservableObject {
    public static let shared = MainTabViewModel()
    
    @Published public var currentTab: Tab = .search
    
    public enum Tab {
        case search
        case favorites
        case downloads
        case account
    }
}
