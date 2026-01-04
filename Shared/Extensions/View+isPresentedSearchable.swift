//
//  View+isPresentedSearchable.swift
//  Atwy
//
//  Created by Antoine Bollengier on 04.01.2026.
//  Copyright © 2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI

struct IsPresentedSearchableModifier: ViewModifier {
    @Binding var search: String
    @Binding var isPresented: Bool
    var placement: SearchFieldPlacement = .automatic
    func body(content: Content) -> some View {
        Group {
            if isPresented {
                content
                    .searchable(text: $search, placement: placement)
            } else {
                content
            }
        }
    }
}

extension View {
    func isPresentedSearchable(search: Binding<String>, isPresented: Binding<Bool>, placement: SearchFieldPlacement = .automatic) -> some View {
        modifier(IsPresentedSearchableModifier(search: search, isPresented: isPresented, placement: placement))
    }
}
