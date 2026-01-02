//
//  ReplyCommentTextFieldStyle.swift
//  Atwy
//
//  Created by Antoine Bollengier on 31.03.2025.
//  Copyright © 2025-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI

struct ReplyCommentTextFieldStyle: TextFieldStyle {
    let borderColor: Color = Color(cgColor: .init(red: 0.85, green: 0.85, blue: 0.85, alpha: 1))
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration.body
            .foregroundStyle(.white)
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(style: .init(lineWidth: 2))
                    .foregroundStyle(borderColor)
            }
    }
}
