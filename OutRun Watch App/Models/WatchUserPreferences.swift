//
//  WatchUserPreferences.swift
//  OutRun Watch App
//
//  Created by Assistant on 1/24/25.
//

import Foundation

class WatchUserPreferences {
    
    // MARK: - Storage Keys
    private enum Keys {
        static let distanceUnit = "watch.distanceUnit"
        static let gpsAccuracy = "watch.gpsAccuracy"
    }
    
    // MARK: - Distance Unit
    @UserDefault(key: Keys.distanceUnit, defaultValue: true)
    static var useKilometers: Bool
    
    static var distanceUnit: UnitLength {
        useKilometers ? .kilometers : .miles
    }
    
    // MARK: - GPS Accuracy
    @UserDefault(key: Keys.gpsAccuracy, defaultValue: nil)
    static var gpsAccuracy: Double?
    
    static var gpsAccuracyDescription: String {
        switch gpsAccuracy {
        case nil:
            return "Standard"
        case 20:
            return "High"
        case 30:
            return "Acceptable"
        case 50:
            return "Last Resort"
        case -1:
            return "Off"
        default:
            return "Standard"
        }
    }
    
    static var gpsAccuracyOptions: [(value: Double?, description: String)] = [
        (nil, "Standard"),
        (20, "High"),
        (30, "Acceptable"),
        (50, "Last Resort"),
        (-1, "Off")
    ]
}

// MARK: - UserDefault Property Wrapper
@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T
    
    init(key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    var wrappedValue: T {
        get {
            UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            if let optional = newValue as? AnyOptional, optional.isNil {
                UserDefaults.standard.removeObject(forKey: key)
            } else {
                UserDefaults.standard.set(newValue, forKey: key)
            }
        }
    }
}

// MARK: - Helper Protocol for Optional Handling
private protocol AnyOptional {
    var isNil: Bool { get }
}

extension Optional: AnyOptional {
    var isNil: Bool { self == nil }
}