//
//  SheetsModel.swift
//  Atwy
//
//  Created by Antoine Bollengier on 22.10.2023.
//

import Foundation

public class SheetsModel: ObservableObject {
    public static let shared = SheetsModel()
    
    @Published private(set) public var shownSheet: (type: SheetType, data: Any?)? = nil
    
    public func showSheet(_ type: SheetType, data: Any? = nil) {
        self.shownSheet = (type, data)
    }
    
    public func hideSheet(_ type: SheetType) {
        self.shownSheet = nil
    }
    
    public enum SheetType: Hashable {
        case addToPlaylist
        case settings
        case watchVideo
    }
}
