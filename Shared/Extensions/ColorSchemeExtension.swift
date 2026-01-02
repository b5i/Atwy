//
//  ColorSchemeExtension.swift
//  Atwy
//
//  Created by Antoine Bollengier on 04.02.23.
//  Copyright © 2023-2026 Antoine Bollengier. All rights reserved.
//

import SwiftUI

extension ColorScheme {

    /// The color that must be used depending on the color style of the device.
    ///
    ///
    /// When you implement a `Text`, you must be sure that is will stay visible whether choice your user do.
    /// The `textColor` attribute provides the right color your `Text` has to be.
    ///
    ///     struct MyView: View {
    ///         @Environment(\.colorScheme) var colorScheme
    ///         var body: some View {
    ///             Text("Hello, World!")
    ///             .foregroundColor(colorScheme.textColor)
    ///         }
    ///     }
    var textColor: Color {
        self == .dark ? .white : .black
    }

    /// The color that must be used depending on the color style of the device.
    ///
    ///
    /// When you implement a `View`, you must be sure that its background will stay in the background whether choice your user do.
    /// The `backgroundColor` attribute provides the right color your `View` has to be.
    ///
    ///     struct MyView: View {
    ///         @Environment(\.colorScheme) var colorScheme
    ///         var body: some View {
    ///             Rectangle()
    ///             .foregroundColor(colorScheme.backgroundColor)
    ///         }
    ///     }
    var backgroundColor: Color {
        self == .dark ? .black : .white
    }
    #if !os(macOS)
    var blurStyle: UIBlurEffect.Style {
        self == .dark ? .systemUltraThinMaterial : .systemThickMaterial
    }
    #endif
}
