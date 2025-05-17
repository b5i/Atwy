//
//  CommentTextField.swift
//  Atwy
//
//  Created by Antoine Bollengier on 31.03.2025.
//  Copyright © 2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI

struct CommentTextField: View {
    @Binding var replyText: String
    @Binding var replyTextSize: CGFloat?
    @FocusState.Binding var isFocused: Bool
    
    private let accessoriesColor: Color = Color(cgColor: .init(red: 0.9, green: 0.9, blue: 0.9, alpha: 1))
    
    var body: some View {
        TextField("Comment", text: self.$replyText, prompt: Text("Comment").foregroundColor(accessoriesColor), axis: .vertical)
            .textFieldStyle(ReplyCommentTextFieldStyle())
            .focused($isFocused)
            .background {
                TextField("CommentHidden", text: self.$replyText, prompt: Text("CommentHidden").foregroundColor(accessoriesColor), axis: .vertical)
                    .textFieldStyle(ReplyCommentTextFieldStyle())
                    .disabled(true)
                    .fixedSize(horizontal: false, vertical: true)
                    .overlay {
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    self.replyTextSize = geometry.size.height
                                }
                        }
                        .id(self.replyText)
                    }
                    .hidden()
            }
    }
}
