//
//  SavableActionDelegate.swift
//  Atwy
//
//  Created by Antoine Bollengier on 18.07.2024.
//  Copyright © 2024-2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

class SavableActionDelegate<Value> where Value: Codable {
    var onGetAction: ((Value) -> Value)?
    
    var onSetAction: ((Value) -> Value)?
}
