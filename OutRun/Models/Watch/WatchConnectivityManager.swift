//
//  WatchConnectivityManager.swift
//
//  OutRun
//  Copyright (C) 2025 CodeOfHonor
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation
import WatchConnectivity
import CoreLocation

class WatchConnectivityManager: NSObject, WCSessionDelegate {
    
    static let shared = WatchConnectivityManager()
    
    private override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error)")
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        processWorkoutData(message)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        processWorkoutData(message)
        replyHandler(["status": "received"])
    }
    
    private func processWorkoutData(_ data: [String: Any]) {
        guard let workoutTypeRaw = data["workoutType"] as? Int,
              let startDate = data["startDate"] as? Date,
              let endDate = data["endDate"] as? Date,
              let distance = data["distance"] as? Double,
              let _ = data["duration"] as? TimeInterval else {
            print("Invalid workout data received from watch")
            return
        }
        
        let workoutType = Workout.WorkoutType(rawValue: workoutTypeRaw)
        
        var tempWorkoutEvents: [TempWorkoutEvent] = []
        if let pauseEventsData = data["pauseEvents"] as? [[String: Any]] {
            for eventData in pauseEventsData {
                if let typeString = eventData["type"] as? String,
                   let date = eventData["date"] as? Date {
                    let eventType: Int
                    switch typeString {
                    case "pause":
                        eventType = 0  // pause
                    case "resume":
                        eventType = 2  // resume
                    default:
                        continue
                    }
                    tempWorkoutEvents.append(TempWorkoutEvent(uuid: nil, eventType: eventType, startDate: date, endDate: date))
                }
            }
        }
        
        var tempRouteData: [TempWorkoutRouteDataSample] = []
        if let locationsData = data["locations"] as? [[String: Any]] {
            for locationData in locationsData {
                if let latitude = locationData["latitude"] as? Double,
                   let longitude = locationData["longitude"] as? Double,
                   let altitude = locationData["altitude"] as? Double,
                   let timestamp = locationData["timestamp"] as? Date,
                   let speed = locationData["speed"] as? Double,
                   let horizontalAccuracy = locationData["horizontalAccuracy"] as? Double,
                   let verticalAccuracy = locationData["verticalAccuracy"] as? Double {
                    
                    let location = CLLocation(
                        coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                        altitude: altitude,
                        horizontalAccuracy: horizontalAccuracy,
                        verticalAccuracy: verticalAccuracy,
                        course: -1,
                        speed: speed,
                        timestamp: timestamp
                    )
                    
                    tempRouteData.append(TempWorkoutRouteDataSample(clLocation: location))
                }
            }
        }
        
        var burnedEnergy: Double?
        if let userWeight = UserPreferences.weight.value {
            burnedEnergy = BurnedEnergyCalculator.calculateBurnedCalories(
                for: workoutType,
                distance: distance,
                weight: userWeight
            ).converting(to: UnitEnergy.standardUnit).value
        }
        
        let tempWorkout = TempWorkout(
            uuid: nil,
            workoutType: workoutType.rawValue,
            startDate: startDate,
            endDate: endDate,
            distance: distance,
            steps: nil,
            isRace: false,
            isUserModified: false,
            comment: nil,
            burnedEnergy: burnedEnergy,
            healthKitUUID: nil,
            workoutEvents: tempWorkoutEvents,
            locations: tempRouteData,
            heartRates: []
        )
        
        let saveWorkout = {
            DataManager.saveWorkout(tempWorkout: tempWorkout, completion: { success, error, _ in
                if success {
                    let banner = TextBanner(text: LS("Workout from Apple Watch saved successfully"))
                    banner.duration = 3
                    banner.show()
                } else {
                    print("Failed to save workout from watch: \(error?.localizedDescription ?? "Unknown error")")
                    let banner = TextBanner(text: LS("Failed to save workout from Apple Watch"))
                    banner.duration = 3
                    banner.show()
                }
            })
        }
        
        DispatchQueue.main.async(execute: saveWorkout)
    }
}
