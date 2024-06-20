//
//  View+tappablePadding.swift
//  Atwy
//
//  Created by Antoine Bollengier on 02.05.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation
import SwiftUI

//https://medium.com/arcush-tech/how-to-increase-a-swiftui-view-tap-area-without-sacrificing-the-layout-1d9e7c9d0dbf
struct TappablePadding: ViewModifier {
  let insets: EdgeInsets
  let onTap: () -> Void
  
  func body(content: Content) -> some View {
    content
      .padding(insets)
      .contentShape(Rectangle())
      .onTapGesture {
        onTap()
      }
      .padding(insets.inverted)
  }
}

extension View {
  func tappablePadding(_ insets: EdgeInsets, onTap: @escaping () -> Void) -> some View {
    self.modifier(TappablePadding(insets: insets, onTap: onTap))
  }
}

extension EdgeInsets {
  var inverted: EdgeInsets {
    .init(top: -top, leading: -leading, bottom: -bottom, trailing: -trailing)
  }
}
