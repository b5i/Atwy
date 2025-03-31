//
//  KeyboardSearchBarView+UITextFieldDelegate.swift
//  Atwy
//
//  Created by Antoine Bollengier on 16.07.2024.
//  Copyright © 2024-2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import UIKit

extension KeyboardSearchBarView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if !isGettingSearchBarHeight {
            textField.resignFirstResponder()
            dismissAction()
            return true
        } else {
            return false
        }
    }
}
