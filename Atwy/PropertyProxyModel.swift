//
//  GeneralProxyModel.swift
//  Atwy
//
//  Created by Antoine Bollengier on 21.02.2025.
//  Copyright © 2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Combine
import SwiftUI
 
class GeneralProxyModel<Object: ObservableObject, Value>: ObservableObject {
    private var object: Object
    @Published fileprivate(set) var value: Value
    private var observers: Set<AnyCancellable> = .init()
    private var transform: (Object) -> Value
    
    init(object: Object, transform: @escaping (Object) -> Value) {
        self.object = object
        self.value = transform(object)
        self.transform = transform
        
        object.objectWillChange
            .receive(on: RunLoop.main) // effectively transforms the willChange into a didChange, otherwise the transform is exectued before the change actually took place and processes old values. the change in the object is still executed on the main thread in handleNewValue https://stackoverflow.com/a/74141342/16456439
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.handleNewValue(self.transform(self.object))
            }
            .store(in: &observers)
    }
    
    fileprivate func handleNewValue(_ newValue: Value) {
        DispatchQueue.main.safeSync {
            self.value = newValue
        }
    }
    
    func getValue<T>(keyPath: KeyPath<Object, T>) -> T {
        return object[keyPath: keyPath]
    }
    
    func setOtherValue<T>(keyPath: WritableKeyPath<Object, T>, value: T) {
        object[keyPath: keyPath] = value
    }
}

extension GeneralProxyModel where Value: Equatable {
    fileprivate func handleNewValue(_ newValue: Value) {
        if self.value != newValue {
            self.value = newValue
        }
    }
}

class PropertyProxyModel<Object: ObservableObject, Value, KeyPathType: KeyPath<Object, Value>>: ObservableObject {
    private var object: Object
    private let keyPath: KeyPathType
    private let propertyPublisherKeyPath: KeyPath<Object, Published<Value>.Publisher>
    @Published fileprivate(set) var value: Value
    private var observers: Set<AnyCancellable> = .init()
    private var transform: (Value) -> Value
    
    init(object: Object, keyPath: KeyPathType, propertyPublisherKeyPath: KeyPath<Object, Published<Value>.Publisher>, transform: @escaping (Value) -> Value = { $0 }) {
        self.object = object
        self.keyPath = keyPath
        self.propertyPublisherKeyPath = propertyPublisherKeyPath
        self.value = transform(object[keyPath: keyPath])
        self.transform = transform
        
        object[keyPath: propertyPublisherKeyPath]
            .sink { [weak self] newValue in
                guard let self = self else { return }
                self.handleNewValue(self.transform(newValue))
            }
            .store(in: &observers)
    }
    
    fileprivate func handleNewValue(_ newValue: Value) {
        self.value = newValue
    }
    
    func getValue<T>(keyPath: KeyPath<Object, T>) -> T {
        return object[keyPath: keyPath]
    }
    
    func setOtherValue<T>(keyPath: WritableKeyPath<Object, T>, value: T) {
        object[keyPath: keyPath] = value
    }
}

extension PropertyProxyModel where KeyPathType: WritableKeyPath<Object, Value> {
    func setValue(_ value: Value) {
        object[keyPath: keyPath] = value
    }
}

extension PropertyProxyModel where Value: Equatable {
    fileprivate func handleNewValue(_ newValue: Value) {
        if self.value != newValue {
            self.value = newValue
        }
    }
}

@propertyWrapper
struct ObservedModel<Object: ObservableObject, Value>: DynamicProperty {
    @StateObject private var model: GeneralProxyModel<Object, Value>
    
    var wrappedValue: Value {
        get { model.value }
    }

    init(_ object: Object, _ transform: @escaping (Object) -> Value) {
        self._model = StateObject(wrappedValue: GeneralProxyModel(object: object, transform: transform))
    }
}

@propertyWrapper
struct ObservedProperty<Object: ObservableObject, Value>: DynamicProperty {
    @StateObject private var model: PropertyProxyModel<Object, Value, KeyPath<Object, Value>>
    
    var wrappedValue: Value {
        get { model.value }
    }

    init(_ object: Object, _ valueKeyPath: KeyPath<Object, Value>, _ propertyPublisherKeyPath: KeyPath<Object, Published<Value>.Publisher>, transform: @escaping (Value) -> Value = { $0 }) {
        self._model = StateObject(wrappedValue: PropertyProxyModel(object: object, keyPath: valueKeyPath, propertyPublisherKeyPath: propertyPublisherKeyPath, transform: transform))
    }
}

@propertyWrapper
struct MutableObservedProperty<Object: ObservableObject, Value>: DynamicProperty {
    @StateObject private var model: PropertyProxyModel<Object, Value, WritableKeyPath<Object, Value>>
    
    var wrappedValue: Value {
        get { model.value }
        nonmutating set { model.setValue(newValue) }
    }

    init(_ object: Object, _ valueKeyPath: WritableKeyPath<Object, Value>, _ propertyPublisherKeyPath: KeyPath<Object, Published<Value>.Publisher>, transform: @escaping (Value) -> Value = { $0 }) {
        self._model = StateObject(wrappedValue: PropertyProxyModel(object: object, keyPath: valueKeyPath, propertyPublisherKeyPath: propertyPublisherKeyPath, transform: transform))
    }
}

class MyModel: ObservableObject {
    @Published var prop1: Int = 0
    @Published var prop2: Int = 0
}

struct MainView: View {
    @State private var obj = MyModel()
    var body: some View {
        Text("Unoptimized example")
        View1(obj: obj)
        View2(obj: obj)
    }
    
    struct View1: View {
        @StateObject var obj: MyModel
        var body: some View {
            Self._printChanges()
            return Text(String(obj.prop1))
                .onTapGesture {
                    obj.prop1 += 1
                }
        }
    }
    
    struct View2: View {
        @StateObject var obj: MyModel
        var body: some View {
            Self._printChanges()
            return Text(String(obj.prop2))
                .onTapGesture {
                    obj.prop2 += 1
                }
        }
    }
}

struct MainView2: View {
    @State private var obj = MyModel()
    var body: some View {
        Text("Optimized example")
        View1(object: obj)
        View2(object: obj)
    }
    
    struct View1: View {
        @MutableObservedProperty<MyModel, Int> private var prop1: Int
        init(object: MyModel) {
            self._prop1 = MutableObservedProperty(object, \.prop1, \.$prop1)
        }
        
        var body: some View {
            Self._printChanges()
            return Text(String(prop1))
                .onTapGesture {
                    self.prop1 += 1
                }
        }
    }
    
    struct View2: View {
        @MutableObservedProperty<MyModel, Int> private var prop2: Int
        init(object: MyModel) {
            self._prop2 = MutableObservedProperty(object, \.prop2, \.$prop2)
        }
        
        var body: some View {
            Self._printChanges()
            return Text(String(prop2))
                .onTapGesture {
                    prop2 += 1
                }
        }
    }
}

#Preview {
    MainView()
    MainView2()
}
