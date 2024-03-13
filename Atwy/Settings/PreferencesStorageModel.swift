//
//  PreferencesStorageModel.swift
//  Atwy
//
//  Created by Antoine Bollengier on 08.10.2023.
//

import Foundation

class PreferencesStorageModel: ObservableObject {
    static let shared = PreferencesStorageModel()
    
    let UD = UserDefaults.standard
    let jsonEncoder = JSONEncoder()
    let jsonDecoder = JSONDecoder()
    
    @Published private(set) var propetriesState: [Properties : any Codable] = [:]
    
    init() {
        reloadData()
    }
    
    public func setNewValueForKey(_ key: Properties, value: Codable?) {
        if let value = value {
            guard type(of: value) == key.getExpectedType() else { print("Attempt to save property failed: received \(String(describing: value)) of type \(type(of: value)) but expected value of type \(key.getExpectedType())."); return }
            if let encoded = try? jsonEncoder.encode(value) {
                UD.setValue(encoded, forKey: key.rawValue)
            } else {
                print("Couldn't encode! Storing temporaily the new value.")
            }
            propetriesState[key] = value
        } else {
            UD.setValue(nil, forKey: key.rawValue)
            propetriesState[key] = nil
        }
    }
    
    private func reloadData() {
        for property in Properties.allCases where UD.object(forKey: property.rawValue) != nil {
            if let data = UD.object(forKey: property.rawValue) as? Data {
                if let value = try? jsonDecoder.decode(property.getExpectedType(), from: data) {
                    propetriesState.updateValue(value, forKey: property)
                }
            }
        }
    }
    
    public enum Properties: String, CaseIterable {
        case videoViewMode
        public enum VideoViewModes: Codable {
            case fullThumbnail
            case halfThumbnail
        }
        
        case performanceMode
        public enum PerformanceModes: Codable {
            case full
            case limited
        }
        case automaticPiP
        case backgroundPlayback
        
        case isLoggerActivated
        case loggerCacheLimit
        case showCredentials
        
        func getExpectedType() -> any Codable.Type {
            switch self {
            case .videoViewMode:
                return VideoViewModes.self
            case .performanceMode:
                return PerformanceModes.self
            case .automaticPiP, .backgroundPlayback, .isLoggerActivated, .showCredentials:
                return Bool.self
            case .loggerCacheLimit:
                return Int.self
            }
        }
    }
}
