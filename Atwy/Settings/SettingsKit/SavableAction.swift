//
//  SavableAction.swift
//  Atwy
//
//  Created by Antoine Bollengier on 18.07.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI

protocol SavableAction: SettingAction {
    associatedtype Value: Codable
    associatedtype Delegate: SavableActionDelegate<Value>
    
    var PSMType: PreferencesStorageModel.Properties { get set }
    
    var valueType: Value.Type { get set }
    
    var delegate: Delegate { get }
    
    func getAction(_ action: @escaping (Value) -> Value) -> Self
    
    func setAction(_ action: @escaping (Value) -> Value) -> Self
    
    var internalValue: State<Value> { get set }
        
    func makeBinding() -> Binding<Value>
}

extension SavableAction {
    func setAction(_ action: @escaping (Value) -> Value) -> Self {
        self.delegate.onSetAction = action
        return self
    }
    
    func getAction(_ action: @escaping (Value) -> Value) -> Self {
        self.delegate.onGetAction = action
        return self
    }
    
    func makeBinding() -> Binding<Value> {
        return .init(get: {
            if let onGetAction = self.delegate.onGetAction {
                return onGetAction(self.internalValue.wrappedValue)
            } else {
                return self.internalValue.wrappedValue
            }
        }, set: { newValue in
            var newValue = newValue
            if let onSetAction = self.delegate.onSetAction {
                newValue = onSetAction(newValue)
            }
            PreferencesStorageModel.shared.setNewValueForKey(self.PSMType, value: newValue)
            self.internalValue.wrappedValue = newValue
        })
    }
    
    var _body: some View {
        body
            .onAppear {
                let state = PreferencesStorageModel.shared.getValueForKey(PSMType) as! Value
                self.internalValue.wrappedValue = state
            }
    }
}
