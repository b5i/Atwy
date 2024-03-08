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
                switch property {
                case .videoViewMode:
                    if let value = try? jsonDecoder.decode(Properties.VideoViewModes.self, from: data) {
                        propetriesState.updateValue(value, forKey: property)
                    }
                case .performanceMode:
                    if let value = try? jsonDecoder.decode(Properties.PerformanceModes.self, from: data) {
                        propetriesState.updateValue(value, forKey: property)
                    }
                case .isLoggerActivated:
                    if let value = try? jsonDecoder.decode(Bool.self, from: data) {
                        propetriesState.updateValue(value, forKey: property)
                    }
                case .loggerCacheLimit:
                    if let value = try? jsonDecoder.decode(Optional<Int>.self, from: data) {
                        propetriesState.updateValue(value, forKey: property)
                    }
                case .showCredentials:
                    if let value = try? jsonDecoder.decode(Bool.self, from: data) {
                        propetriesState.updateValue(value, forKey: property)
                    }
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
        
        case isLoggerActivated
        case loggerCacheLimit
        case showCredentials
    }
}
