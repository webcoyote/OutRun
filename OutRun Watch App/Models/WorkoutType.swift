//
//  WorkoutType.swift
//  OutRun Watch App
//
//  Created on 2025-07-23.
//

import Foundation
import HealthKit

enum WorkoutType: Int, CaseIterable {
    case running = 0
    case walking = 1
    case cycling = 2
    case skating = 3
    case hiking = 4
    
    var displayName: String {
        switch self {
        case .running:
            return "Running"
        case .walking:
            return "Walking"
        case .cycling:
            return "Cycling"
        case .skating:
            return "Skating"
        case .hiking:
            return "Hiking"
        }
    }
    
    var healthKitType: HKWorkoutActivityType {
        switch self {
        case .running:
            return .running
        case .walking:
            return .walking
        case .cycling:
            return .cycling
        case .skating:
            return .skatingSports
        case .hiking:
            return .hiking
        }
    }
}

struct WorkoutPauseEvent {
    enum EventType: String {
        case pause
        case resume
    }
    
    let type: EventType
    let date: Date
}