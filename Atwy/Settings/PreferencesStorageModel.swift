//
//  PreferencesStorageModel.swift
//  Atwy
//
//  Created by Antoine Bollengier on 08.10.2023.
//

import Foundation
import OSLog

class PreferencesStorageModel: ObservableObject {
    static let shared = PreferencesStorageModel()
    
    let UD = UserDefaults.standard
    let jsonEncoder = JSONEncoder()
    let jsonDecoder = JSONDecoder()
    
    @Published private(set) var propetriesState: [Properties : any Codable] = [:]
    
    init() {
        reloadData()
        
        // TODO: remove that in a future version
        if let mode = propetriesState[.performanceMode] as? Properties.PerformanceModes {
            self.setNewValueForKey(.performanceModeEnabled, value: mode == .full)
        }
    }
    
    public func getValueForKey(_ key: Properties) -> Codable {
        return self.propetriesState[key] ?? key.getDefaultValue()
    }
    
    public func setNewValueForKey(_ key: Properties, value: Codable?) {
        if let value = value {
            guard type(of: value) == key.getExpectedType() else { Logger.atwyLogs.simpleLog("Attempt to save property failed: received \(String(describing: value)) of type \(type(of: value)) but expected value of type \(key.getExpectedType())."); return }
            if let encoded = try? jsonEncoder.encode(value) {
                UD.setValue(encoded, forKey: key.rawValue)
            } else {
                Logger.atwyLogs.simpleLog("Couldn't encode! Storing temporaily the new value.")
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
        case favoritesSortingMode
        case downloadsSortingMode
        public enum SortingModes: Codable {
            case newest, oldest
            case title
            case channelName
        }
        
        case videoViewMode
        public enum VideoViewModes: Codable {
            case fullThumbnail
            case halfThumbnail
        }
        
        // use performanceModeEnabled instead
        case performanceMode
        public enum PerformanceModes: Codable {
            case full
            case limited
        }
        
        case performanceModeEnabled
        
        case liveActivitiesEnabled
        case automaticPiP
        case backgroundPlayback
        
        case isLoggerActivated
        case loggerCacheLimit
        case showCredentials
        
        case customAVButtonsEnabled
        case variableBlurEnabled
        case customSearchBarEnabled
        
        // private storage
        
        case searchBarHeight
        
        func getExpectedType() -> any Codable.Type {
            switch self {
            case .favoritesSortingMode, .downloadsSortingMode:
                return SortingModes.self
            case .videoViewMode:
                return VideoViewModes.self
            case .performanceMode:
                return PerformanceModes.self
            case .liveActivitiesEnabled, .automaticPiP, .backgroundPlayback, .isLoggerActivated, .showCredentials, .customAVButtonsEnabled, .variableBlurEnabled, .customSearchBarEnabled, .performanceModeEnabled:
                return Bool.self
            case .loggerCacheLimit:
                return Int.self
            case .searchBarHeight:
                return CGFloat.self
            }
        }
        
        func getDefaultValue() -> any Codable {
            switch self {
            case .favoritesSortingMode, .downloadsSortingMode:
                return SortingModes.newest
            case .videoViewMode:
                return VideoViewModes.fullThumbnail
            case .performanceMode:
                return PerformanceModes.full
            case .liveActivitiesEnabled, .automaticPiP, .backgroundPlayback, .customAVButtonsEnabled, .variableBlurEnabled, .customSearchBarEnabled, .performanceModeEnabled:
                return true
            case .isLoggerActivated, .showCredentials:
                return false
            case .loggerCacheLimit:
                return 5
            case .searchBarHeight:
                return 0
            }
        }
    }
}

extension PreferencesStorageModel {
    var customAVButtonsEnabled: Bool {
        (PreferencesStorageModel.shared.propetriesState[.customAVButtonsEnabled] as? Bool) ?? false
    }
}
