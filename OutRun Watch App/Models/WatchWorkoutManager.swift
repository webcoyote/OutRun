//
//  WatchWorkoutManager.swift
//  OutRun Watch App
//
//  Created on 2025-07-23.
//

import Foundation
import CoreLocation
import HealthKit
import WatchConnectivity

class WatchWorkoutManager: NSObject, ObservableObject {
    
    @Published var isWorkoutActive = false
    @Published var isPaused = false
    @Published var workoutType: WorkoutType = .running
    @Published var duration: TimeInterval = 0
    @Published var distance: Double = 0
    @Published var pace: Double = 0
    @Published var heartRate: Double?
    
    private var healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var locationManager: CLLocationManager?
    
    private var startDate: Date?
    private var pauseEvents: [WorkoutPauseEvent] = []
    private var locations: [CLLocation] = []
    
    private var timer: Timer?
    private let session = WCSession.default
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    var formattedDistance: String {
        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.2f km", distance / 1000)
        }
    }
    
    var formattedPace: String {
        guard distance > 0 else { return "--:--" }
        let paceInSecondsPerKm = (duration / distance) * 1000
        let minutes = Int(paceInSecondsPerKm) / 60
        let seconds = Int(paceInSecondsPerKm) % 60
        return String(format: "%d:%02d /km", minutes, seconds)
    }
    
    override init() {
        super.init()
        setupWatchConnectivity()
        requestAuthorization()
        setupLocationManager()
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.activityType = .fitness
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.requestAlwaysAuthorization()
    }
    
    private func requestAuthorization() {
        let typesToShare: Set = [
            HKQuantityType.workoutType()
        ]
        
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .distanceCycling)!,
            HKObjectType.activitySummaryType()
        ]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if !success {
                print("HealthKit authorization failed: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    func startWorkout(type: WorkoutType) {
        workoutType = type
        startDate = Date()
        locations.removeAll()
        pauseEvents.removeAll()
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = type.healthKitType
        configuration.locationType = .outdoor
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()
            
            workoutSession?.delegate = self
            workoutBuilder?.delegate = self
            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
            
            workoutSession?.startActivity(with: Date())
            workoutBuilder?.beginCollection(withStart: Date()) { success, error in
                if success {
                    DispatchQueue.main.async {
                        self.isWorkoutActive = true
                        self.isPaused = false
                        self.startTimer()
                        self.locationManager?.startUpdatingLocation()
                    }
                }
            }
        } catch {
            print("Failed to start workout: \(error)")
        }
    }
    
    func togglePause() {
        if isPaused {
            resumeWorkout()
        } else {
            pauseWorkout()
        }
    }
    
    private func pauseWorkout() {
        workoutSession?.pause()
        isPaused = true
        pauseEvents.append(WorkoutPauseEvent(type: .pause, date: Date()))
        locationManager?.stopUpdatingLocation()
    }
    
    private func resumeWorkout() {
        workoutSession?.resume()
        isPaused = false
        pauseEvents.append(WorkoutPauseEvent(type: .resume, date: Date()))
        locationManager?.startUpdatingLocation()
    }
    
    func endWorkout() {
        locationManager?.stopUpdatingLocation()
        timer?.invalidate()
        
        workoutSession?.end()
        workoutBuilder?.endCollection(withEnd: Date()) { success, error in
            self.workoutBuilder?.finishWorkout { workout, error in
                DispatchQueue.main.async {
                    self.isWorkoutActive = false
                    self.isPaused = false
                    self.duration = 0
                    self.distance = 0
                    self.pace = 0
                    self.heartRate = nil
                    
                    if let workout = workout {
                        self.saveWorkoutData()
                    }
                }
            }
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if !self.isPaused {
                self.updateDuration()
            }
        }
    }
    
    private func updateDuration() {
        guard let start = startDate else { return }
        
        var totalDuration = Date().timeIntervalSince(start)
        
        for i in stride(from: 0, to: pauseEvents.count, by: 2) {
            let pauseEvent = pauseEvents[i]
            if i + 1 < pauseEvents.count {
                let resumeEvent = pauseEvents[i + 1]
                totalDuration -= resumeEvent.date.timeIntervalSince(pauseEvent.date)
            } else {
                totalDuration -= Date().timeIntervalSince(pauseEvent.date)
            }
        }
        
        duration = totalDuration
    }
    
    private func saveWorkoutData() {
        guard let startDate = startDate else { return }
        
        let workoutData: [String: Any] = [
            "workoutType": workoutType.rawValue,
            "startDate": startDate,
            "endDate": Date(),
            "distance": distance,
            "duration": duration,
            "pauseEvents": pauseEvents.map { ["type": $0.type.rawValue, "date": $0.date] },
            "locations": locations.map { location in
                [
                    "latitude": location.coordinate.latitude,
                    "longitude": location.coordinate.longitude,
                    "altitude": location.altitude,
                    "timestamp": location.timestamp,
                    "speed": location.speed,
                    "horizontalAccuracy": location.horizontalAccuracy,
                    "verticalAccuracy": location.verticalAccuracy
                ]
            }
        ]
        
        if session.isReachable {
            session.sendMessage(workoutData, replyHandler: nil) { error in
                print("Failed to send workout data: \(error)")
                self.storeWorkoutLocally(workoutData)
            }
        } else {
            storeWorkoutLocally(workoutData)
        }
    }
    
    private func storeWorkoutLocally(_ workoutData: [String: Any]) {
        if var storedWorkouts = UserDefaults.standard.array(forKey: "PendingWorkouts") as? [[String: Any]] {
            storedWorkouts.append(workoutData)
            UserDefaults.standard.set(storedWorkouts, forKey: "PendingWorkouts")
        } else {
            UserDefaults.standard.set([workoutData], forKey: "PendingWorkouts")
        }
    }
}

extension WatchWorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed: \(error)")
    }
}

extension WatchWorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        
    }
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }
            
            if quantityType == HKQuantityType.quantityType(forIdentifier: .heartRate) {
                if let statistics = workoutBuilder.statistics(for: quantityType) {
                    DispatchQueue.main.async {
                        self.heartRate = statistics.mostRecentQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                    }
                }
            } else if quantityType == HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) ||
                      quantityType == HKQuantityType.quantityType(forIdentifier: .distanceCycling) {
                if let statistics = workoutBuilder.statistics(for: quantityType) {
                    DispatchQueue.main.async {
                        self.distance = statistics.sumQuantity()?.doubleValue(for: .meter()) ?? 0
                    }
                }
            }
        }
    }
}

extension WatchWorkoutManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        self.locations.append(location)
        
        if !isPaused && location.horizontalAccuracy > 0 {
            if let lastLocation = self.locations.dropLast().last {
                let delta = location.distance(from: lastLocation)
                if delta > 0 && delta < 100 {
                    DispatchQueue.main.async {
                        self.distance += delta
                    }
                }
            }
        }
    }
}

extension WatchWorkoutManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            syncPendingWorkouts()
        }
    }
    
    private func syncPendingWorkouts() {
        guard session.isReachable,
              let pendingWorkouts = UserDefaults.standard.array(forKey: "PendingWorkouts") as? [[String: Any]],
              !pendingWorkouts.isEmpty else { return }
        
        for workout in pendingWorkouts {
            session.sendMessage(workout, replyHandler: { _ in
                if var remaining = UserDefaults.standard.array(forKey: "PendingWorkouts") as? [[String: Any]] {
                    remaining.removeAll { $0["startDate"] as? Date == workout["startDate"] as? Date }
                    UserDefaults.standard.set(remaining, forKey: "PendingWorkouts")
                }
            }) { error in
                print("Failed to sync workout: \(error)")
            }
        }
    }
}