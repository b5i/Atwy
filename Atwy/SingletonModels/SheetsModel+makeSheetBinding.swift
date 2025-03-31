//
//  SheetsModel+makeSheetBinding.swift
//  Atwy
//
//  Created by Antoine Bollengier on 22.10.2023.
//  Copyright © 2023-2025 Antoine Bollengier. All rights reserved.
//

import SwiftUI

public extension SheetsModel {
    func makeSheetBinding(_ type: SheetType) -> Binding<Bool> {
        return Binding(get: {
            return self.shownSheet?.type == type
        }, set: { newValue in
            if newValue {
                self.showSheet(type)
            } else {
                self.hideSheet(type)
            }
        })
    }
}
