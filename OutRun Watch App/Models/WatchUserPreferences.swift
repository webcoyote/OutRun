//
//  WatchUserPreferences.swift
//  OutRun Watch App
//
//  Created by Assistant on 1/24/25.
//

import Foundation

// MARK: - Unit Enums
enum DistanceUnit: String, CaseIterable {
    case system = "system"
    case miles = "miles"
    case kilometers = "kilometers"
    
    var unitLength: UnitLength {
        switch self {
        case .system:
            return Locale.current.usesMetricSystem ? .kilometers : .miles
        case .miles: return .miles
        case .kilometers: return .kilometers
        }
    }
    
    var displayName: String {
        switch self {
        case .system:
            let unit = Locale.current.usesMetricSystem ? "km" : "miles"
            return "Standard (\(unit))"
        case .miles: return "Miles"
        case .kilometers: return "Kilometers"
        }
    }
}

enum AltitudeUnit: String, CaseIterable {
    case system = "system"
    case feet = "feet"
    case meters = "meters"
    
    var unitLength: UnitLength {
        switch self {
        case .system:
            return Locale.current.usesMetricSystem ? .meters : .feet
        case .feet: return .feet
        case .meters: return .meters
        }
    }
    
    var displayName: String {
        switch self {
        case .system:
            let unit = Locale.current.usesMetricSystem ? "meters" : "feet"
            return "Standard (\(unit))"
        case .feet: return "Feet"
        case .meters: return "Meters"
        }
    }
}

class WatchUserPreferences {
    
    // MARK: - Storage Keys
    private enum Keys {
        static let distanceUnit = "watch.distanceUnit"
        static let altitudeUnit = "watch.altitudeUnit"
        static let gpsAccuracy = "watch.gpsAccuracy"
    }
    
    // MARK: - Distance Unit
    @UserDefault(key: Keys.distanceUnit, defaultValue: DistanceUnit.system.rawValue)
    static var distanceUnitRaw: String
    
    static var distanceUnit: DistanceUnit {
        get { DistanceUnit(rawValue: distanceUnitRaw) ?? .system }
        set { distanceUnitRaw = newValue.rawValue }
    }
    
    // MARK: - Altitude Unit
    @UserDefault(key: Keys.altitudeUnit, defaultValue: AltitudeUnit.system.rawValue)
    static var altitudeUnitRaw: String
    
    static var altitudeUnit: AltitudeUnit {
        get { AltitudeUnit(rawValue: altitudeUnitRaw) ?? .system }
        set { altitudeUnitRaw = newValue.rawValue }
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
