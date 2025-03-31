//
//  SAStepper.swift
//  Atwy
//
//  Created by Antoine Bollengier on 18.07.2024.
//  Copyright © 2024-2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI

struct SAStepper<Value>: SavableAction where Value: Strideable & Codable {
    init(valueType: Value.Type, PSMType: PreferencesStorageModel.Properties, title: String) throws {
        self.valueType = valueType
        self.PSMType = PSMType
        self.title = title
        guard valueType == PSMType.getExpectedType() else { throw "ValueTypes are not equal: got PSMType with type \(String(describing: PSMType.getExpectedType())) but expected \(String(describing: valueType))" }
        let state = PreferencesStorageModel.shared.getValueForKey(PSMType) as! Value
        self._currentValue = State(wrappedValue: state)
    }
    
    let title: String
    
    @State var currentValue: Value
    
    var internalValue: State<Value> {
        get { _currentValue }
        set { _currentValue = newValue }
    }
    
    var valueType: Value.Type
    
    var PSMType: PreferencesStorageModel.Properties
    
    @ObservedObject var delegate: Delegate = .init()
        
    var body: some View {
        let binding = makeBinding()
        Stepper(value: binding, step: self.delegate.step ?? 1, label: {
            HStack {
                Text(title)
            }
        })
        .badge(String("\(binding.wrappedValue)"))
    }
    
    func step(_ step: Value.Stride) -> Self {
        self.delegate.step = step
        return self
    }
    
    class Delegate: SavableActionDelegate<Value>, ObservableObject {
        @Published var step: Value.Stride?
    }
}
