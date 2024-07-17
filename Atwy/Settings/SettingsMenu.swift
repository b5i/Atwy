//
//  SettingsMenu.swift
//  Atwy
//
//  Created by Antoine Bollengier on 17.07.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI

struct SettingsMenu<HeaderView>: View where HeaderView: View {
    var title: String
    
    var header: (() -> HeaderView)?
    
    var sections: [SettingsSection]
    
    init(title: String, @ViewBuilder header: (@escaping () -> HeaderView), sections: [SettingsSection]) {
        self.title = title
        self.header = header
        self.sections = sections
    }
    
    init(title: String, sections: [SettingsSection]) {
        self.title = title
        self.header = nil
        self.sections = sections
    }
    
    var body: some View {
        List {
            if let header = self.header {
                header()
            }
            ForEach(Array(sections.enumerated()), id: \.offset) { (_, section) in
                section
            }
        }
        .navigationTitle(title)
    }
}

struct SettingsSection: View {
    var title: String
    
    var settings: [Setting]
    
    var body: some View {
        Section(title) {
            ForEach(Array(settings.enumerated()), id: \.offset) { (_, setting) in
                AnyView(setting)
            }
        }
    }
}

struct Setting: View {
    let textDescription: String?
        
    let action: any SettingAction
    
    var privateAPIWarning: Bool = false
    
    var hidden: Bool = false
    
    var body: some View {
        if hidden {
            EmptyView()
        } else {
            VStack(alignment: .leading) {
                AnyView(action)
                if let textDescription = self.textDescription {
                    Text(textDescription)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if privateAPIWarning {
                    Label("Private APIs checks have failed for this option, therefore you can't enable it for safety reasons.", systemImage: "exclamationmark.triangle.fill")
                        .labelStyle(FailedInitPrivateAPILabelStyle())
                }
            }
            .disabled(privateAPIWarning)
        }
    }
}

protocol SettingAction: View {
    associatedtype InternalActionView: View
    
    var title: String { get }
                
    @ViewBuilder var _body: InternalActionView { get }
}

extension SettingAction {
    var _body: some View {
        body
    }
}

protocol SavableAction: SettingAction {
    associatedtype Value: Codable
    
    var PSMType: PreferencesStorageModel.Properties { get set }
    
    var valueType: Value.Type { get set }
    
    var onGetAction: ((Value) -> Value)? { get nonmutating set }
    
    func getAction(_ action: @escaping (Value) -> Value) -> Self

    var onSetAction: ((Value) -> Value)? { get nonmutating set }
    
    func setAction(_ action: @escaping (Value) -> Value) -> Self
    
    var internalValue: State<Value> { get set }
        
    func makeBinding() -> Binding<Value>
}

extension SavableAction {
    func setAction(_ action: @escaping (Value) -> Value) -> Self {
        self.onSetAction = action
        return self
    }
    
    func getAction(_ action: @escaping (Value) -> Value) -> Self {
        self.onGetAction = action
        return self
    }
    
    func makeBinding() -> Binding<Value> {
        return .init(get: {
            if let onGetAction = self.onGetAction {
                return onGetAction(self.internalValue.wrappedValue)
            } else {
                return self.internalValue.wrappedValue
            }
        }, set: { newValue in
            PreferencesStorageModel.shared.setNewValueForKey(self.PSMType, value: newValue)
            if let onSetAction = self.onSetAction {
                self.internalValue.wrappedValue = onSetAction(newValue)
            } else {
                self.internalValue.wrappedValue = newValue
            }
        })
    }
    
    var _body: some View {
        body
            .onAppear {
                if let state = PreferencesStorageModel.shared.propetriesState[PSMType] as? Value {
                    self.internalValue.wrappedValue = state
                } else {
                    let defaultMode = PSMType.getDefaultValue() as? Value ?? PSMType.getDefaultValue() as! Value
                    self.internalValue.wrappedValue = defaultMode
                }
            }
    }
}



struct SAStepper<Value>: SavableAction where Value: Strideable & Codable {
    init(valueType: Value.Type, PSMType: PreferencesStorageModel.Properties, title: String) throws {
        self.valueType = valueType
        self.PSMType = PSMType
        self.title = title
        guard valueType == PSMType.getExpectedType() else { throw "ValueTypes are not equal: got PSMType with type \(String(describing: PSMType.getExpectedType())) but expected \(String(describing: valueType))" }
        if let state = PreferencesStorageModel.shared.propetriesState[PSMType] as? Value {
            self._currentValue = State(wrappedValue: state)
        } else {
            let defaultMode = PSMType.getDefaultValue() as! Value
            self._currentValue = State(wrappedValue: defaultMode)
        }
    }
    
    let title: String
    
    @State var currentValue: Value
    
    var internalValue: State<Value> {
        get { _currentValue }
        set { _currentValue = newValue }
    }
    
    var valueType: Value.Type
        
    @State private var step: Value.Stride? = nil
        
    var PSMType: PreferencesStorageModel.Properties
    
    @State var onGetAction: ((Value) -> Value)? = nil

    @State var onSetAction: ((Value) -> Value)? = nil
        
    var body: some View {
        let binding = makeBinding()
        Stepper(value: binding, step: self.step ?? 1, label: {
            HStack {
                Text(title)
            }
        })
        .badge(String("\(binding.wrappedValue)"))
    }
    
    func step(_ step: Value.Stride) -> Self {
        self.step = step
        return self
    }
}

struct SAToggle<TStyle>: SavableAction where TStyle: ToggleStyle {
    init(PSMType: PreferencesStorageModel.Properties, title: String, toggleStyle: TStyle = .automatic) throws {
        self.PSMType = PSMType
        self.title = title
        self.toggleStyle = toggleStyle
        guard valueType == PSMType.getExpectedType() else { throw "ValueTypes are not equal: got PSMType with type \(String(describing: PSMType.getExpectedType())) but expected \(String(describing: valueType))" }
        if let state = PreferencesStorageModel.shared.propetriesState[PSMType] as? Bool {
            self._currentValue = State(wrappedValue: state)
        } else {
            let defaultMode = PSMType.getDefaultValue() as! Bool
            self._currentValue = State(wrappedValue: defaultMode)
        }
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
    
    @State var onGetAction: ((Bool) -> Value)? = nil

    @State var onSetAction: ((Bool) -> Value)? = nil
        
    var body: some View {
        let binding = makeBinding()
        Toggle(title, isOn: binding)
            .toggleStyle(self.toggleStyle)
    }
}

struct SATextButton: SettingAction {
    let title: String
    
    let buttonLabel: String
    
    let action: (_ showHideButton: @escaping (Bool) -> Void) -> Void
    
    @State private var showButton: Bool = true
            
    var body: some View {
        HStack {
            if !title.isEmpty {
                Text(title)
                Spacer()
            }
            
            if showButton {
                Button(buttonLabel, action: {
                    action { self.showButton = $0 }
                })
            } else {
                ProgressView()
            }
        }
    }
}

struct SACustomAction<ActionView>: SettingAction where ActionView: View {
    let title: String
    
    let actionView: ActionView
    
    var body: some View {
        actionView
    }
}

#Preview {
    NavigationStack {
        SettingsMenu<Never>(title: "Account", sections: [
            SettingsSection(title: "Test", settings: [
                Setting(textDescription: "Test description", action: try! SAStepper(valueType: Int.self, PSMType: .loggerCacheLimit, title: "Limit"), privateAPIWarning: true),
                Setting(textDescription: "Test description", action: try! SAStepper(valueType: Int.self, PSMType: .loggerCacheLimit, title: "Limit").step(2)),
                Setting(textDescription: "Auto PiP", action: try! SAToggle(PSMType: .automaticPiP, title: "Auto PiP"))
            ]),
            SettingsSection(title: "Test", settings: [
                Setting(textDescription: nil, action: try! SAToggle(PSMType: .automaticPiP, title: "Auto PiP")),
                Setting(textDescription: nil, action: try! SATextButton(title: "Auto PiP", buttonLabel: "Reset", action: {_ in})),
                Setting(textDescription: "This will reset your iPhone.", action: try! SATextButton(title: "", buttonLabel: "Reset", action: {_ in})),
                Setting(textDescription: "This will reset your iPhone.", action: try! SAToggle(PSMType: .performanceModeEnabled, title: "Performance mode", toggleStyle: PerformanceModeToggleStyle()))
            ])
        ])
    }
}

struct PerformanceModeToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundStyle(.ultraThickMaterial)
                HStack {
                    if !configuration.isOn {
                        Spacer()
                    }
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundStyle(.orange)
                        .frame(width: geometry.size.width * 0.28, height: geometry.size.height * 0.08)
                        .padding(.horizontal)
                    if configuration.isOn {
                        Spacer()
                    }
                }
                HStack {
                    HStack {
                        Spacer()
                        Text("Full")
                        Image(systemName: "hare.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25, height: 25)
                        Spacer()
                    }
                    .onTapGesture {
                        withAnimation(.spring) {
                            configuration.$isOn.wrappedValue = true
                        }
                    }
                    Spacer()
                    HStack {
                        Spacer()
                        Text("Limited")
                        Image(systemName: "tortoise.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25, height: 25)
                        Spacer()
                    }
                    .onTapGesture {
                        withAnimation(.spring) {
                            configuration.$isOn.wrappedValue = false
                        }
                    }
                }
            }
            .frame(width: 300, height: 75)
            .centered()
        }
    }
}
