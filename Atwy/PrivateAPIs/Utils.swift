//
//  Utils.swift
//  Atwy
//
//  Created by Antoine Bollengier on 29.03.2024.
//  Copyright © 2024-2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import Foundation

func getMethodsForProtocol(_ protocolToUse: Protocol) -> [(Selector, arguments: UnsafeMutablePointer<CChar>, textDescription: String)] {
    let runtime = dlopen(nil, RTLD_NOW)
    let _protocol_getMethodTypeEncodingPtr = dlsym(runtime, "_protocol_getMethodTypeEncoding")
    let _protocol_getMethodTypeEncoding = unsafeBitCast(_protocol_getMethodTypeEncodingPtr, to: (@convention(c) (Protocol, Selector, Bool, Bool) -> UnsafePointer<Int8>?).self)

    var toReturn: [(Selector, arguments: UnsafeMutablePointer<CChar>, textDescription: String)] = []
    var methodCount: [UInt32] = [0] // value that will be used to store the number of selectors
    methodCount.withUnsafeMutableBytes { methodCountPtr in
        let castedPtr = methodCountPtr.assumingMemoryBound(to: UInt32.self).baseAddress!
        if let methodList = protocol_copyMethodDescriptionList(protocolToUse, true, true, castedPtr) {
            for i in 0..<Int(castedPtr.pointee) {
                let methodDesc = methodList[i];
                let name = methodDesc.name
                
                let result = _protocol_getMethodTypeEncoding(protocolToUse, name!, true, true)
                
                toReturn.append((methodDesc.name!, methodDesc.types!, String(cString: result!)))
            }
        }
        
        if let methodList = protocol_copyMethodDescriptionList(protocolToUse, false /* optional methods */, true, castedPtr) {
            for i in 0..<Int(castedPtr.pointee) {
                let methodDesc = methodList[i];
                let name = methodDesc.name
                
                let result = _protocol_getMethodTypeEncoding(protocolToUse, name!, false /* optional methods */, true)
                
                toReturn.append((methodDesc.name!, methodDesc.types!, String(cString: result!)))
            }
        }
    }
    dlclose(runtime)
    return toReturn
}

extension NSObject {
    static func perform(_ aSelector: Selector, with arg1: Any, with arg2: Any, with arg3: Any) -> Unmanaged<AnyObject>! {
        let specialInit = (@convention(c) (NSObject.Type, Selector, Any, Any, Any) -> Unmanaged<AnyObject>).self
        let implementation = self.method(for: aSelector)
        let method = unsafeBitCast(implementation, to: specialInit)
        return method(self, aSelector, arg1, arg2, arg3)
    }
    
    static func perform(_ aSelector: Selector, with arg1: Any, with arg2: Any, with arg3: Any, with arg4: Any) -> Unmanaged<AnyObject>! {
        let specialInit = (@convention(c) (NSObject.Type, Selector, Any, Any, Any, Any) -> Unmanaged<AnyObject>).self
        let implementation = self.method(for: aSelector)
        let method = unsafeBitCast(implementation, to: specialInit)
        return method(self, aSelector, arg1, arg2, arg3, arg4)
    }
    
    static func perform(_ aSelector: Selector, with arg1: Any, with arg2: Any, with arg3: Any, with arg4: Any, with arg5: Any) -> Unmanaged<AnyObject>! {
        let specialInit = (@convention(c) (NSObject.Type, Selector, Any, Any, Any, Any, Any) -> Unmanaged<AnyObject>).self
        let implementation = self.method(for: aSelector)
        let method = unsafeBitCast(implementation, to: specialInit)
        return method(self, aSelector, arg1, arg2, arg3, arg4, arg5)
    }
    
    func perform(_ aSelector: Selector, with arg1: Any, with arg2: Any, with arg3: Any) -> Unmanaged<AnyObject>! {
        let specialInit = (@convention(c) (NSObject, Selector, Any, Any, Any) -> Unmanaged<AnyObject>).self
        let implementation = self.method(for: aSelector)
        let method = unsafeBitCast(implementation, to: specialInit)
        return method(self, aSelector, arg1, arg2, arg3)
    }
    
    func perform(_ aSelector: Selector, with arg1: Any, with arg2: Any, with arg3: Any, with arg4: Any) -> Unmanaged<AnyObject>! {
        let specialInit = (@convention(c) (NSObject, Selector, Any, Any, Any, Any) -> Unmanaged<AnyObject>).self
        let implementation = self.method(for: aSelector)
        let method = unsafeBitCast(implementation, to: specialInit)
        return method(self, aSelector, arg1, arg2, arg3, arg4)
    }
    
    func perform(_ aSelector: Selector, with arg1: Any, with arg2: Any, with arg3: Any, with arg4: Any, with arg5: Any) -> Unmanaged<AnyObject>! {
        let specialInit = (@convention(c) (NSObject, Selector, Any, Any, Any, Any, Any) -> Unmanaged<AnyObject>).self
        let implementation = self.method(for: aSelector)
        let method = unsafeBitCast(implementation, to: specialInit)
        return method(self, aSelector, arg1, arg2, arg3, arg4, arg5)
    }
}
