//
//  SAToggle.swift
//  Atwy
//
//  Created by Antoine Bollengier on 18.07.2024.
//  Copyright © 2024-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI

struct SAToggle<TStyle>: SavableAction where TStyle: ToggleStyle {
    init(PSMType: PreferencesStorageModel.Properties, title: String, toggleStyle: TStyle = .automatic) throws {
        self.PSMType = PSMType
        self.title = title
        self.toggleStyle = toggleStyle
        guard valueType == PSMType.getExpectedType() else { throw "ValueTypes are not equal: got PSMType with type \(String(describing: PSMType.getExpectedType())) but expected \(String(describing: valueType))" }
        let state = PreferencesStorageModel.shared.getValueForKey(PSMType) as! Bool
        self._currentValue = State(wrappedValue: state)
    }
    
    let title: String
    
    let toggleStyle: TStyle
    
    @State var currentValue: Bool
        
    var internalValue: State<Bool> {
        get { _currentValue }
        set { _currentValue = newValue }
    }
    
    var valueType = Bool.self
                
    var PSMType: PreferencesStorageModel.Properties
    
    let delegate: Delegate = .init()
        
    var body: some View {
        let binding = makeBinding()
        Toggle(title, isOn: binding)
            .toggleStyle(self.toggleStyle)
    }
    
    class Delegate: SavableActionDelegate<Bool> {}
    
    func setCallback(_ callback: @escaping (Bool) -> Void) -> Self {
        self.delegate.onSetAction = { callback($0); return $0 }
        return self
    }
}
