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
    @Published var workoutError: String?
    
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
        let distanceUnit = WatchUserPreferences.distanceUnit
        
        if distanceUnit == .kilometers {
            if distance < 1000 {
                return String(format: "%.0f m", distance)
            } else {
                return String(format: "%.2f km", distance / 1000)
            }
        } else {
            let distanceInMiles = distance * 0.000621371
            if distanceInMiles < 0.1 {
                let distanceInFeet = distance * 3.28084
                return String(format: "%.0f ft", distanceInFeet)
            } else {
                return String(format: "%.2f mi", distanceInMiles)
            }
        }
    }
    
    var formattedPace: String {
        guard distance > 10 else { return "--:--" }
        let distanceUnit = WatchUserPreferences.distanceUnit
        
        if distanceUnit == .kilometers {
            let paceInSecondsPerKm = (duration / distance) * 1000
            guard paceInSecondsPerKm < Double(Int.max) else { return "--:--" }
            let minutes = Int(paceInSecondsPerKm) / 60
            let seconds = Int(paceInSecondsPerKm) % 60
            return String(format: "%d:%02d/km", minutes, seconds)
        } else {
            let paceInSecondsPerMile = (duration / distance) * 1609.344
            guard paceInSecondsPerMile < Double(Int.max) else { return "--:--" }
            let minutes = Int(paceInSecondsPerMile) / 60
            let seconds = Int(paceInSecondsPerMile) % 60
            return String(format: "%d:%02d/mi", minutes, seconds)
        }
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
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
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
        workoutError = nil
        isWorkoutActive = true
        
        // Check if health data is available
        guard HKHealthStore.isHealthDataAvailable() else {
            DispatchQueue.main.async {
                self.workoutError = "Health data not available"
                self.isWorkoutActive = false
            }
            return
        }
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = type.healthKitType
        configuration.locationType = .outdoor
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()
            
            // Set delegates before starting
            workoutSession?.delegate = self
            workoutBuilder?.delegate = self
            
            // Create and set data source
            let dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
            workoutBuilder?.dataSource = dataSource
            
            // Start the workout session and collection together
            let startDate = Date()
            workoutSession?.startActivity(with: startDate)
            
            workoutBuilder?.beginCollection(withStart: startDate) { [weak self] success, error in
                if let error = error {
                    print("Failed to begin collection: \(error)")
                    DispatchQueue.main.async {
                        self?.workoutError = "Failed to start workout: \(error.localizedDescription)"
                        self?.isWorkoutActive = false
                    }
                }
            }
            
            // Start timer and location updates immediately
            self.startTimer()
            self.locationManager?.startUpdatingLocation()
        } catch {
            print("Failed to start workout: \(error)")
            DispatchQueue.main.async {
                self.workoutError = "Failed to create workout session: \(error.localizedDescription)"
                self.isWorkoutActive = false
            }
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
                    
                    if workout != nil {
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
            "id": UUID().uuidString,
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
        print("Workout session state changed from \(fromState.rawValue) to \(toState.rawValue)")
        
        DispatchQueue.main.async {
            switch toState {
            case .running:
                self.isWorkoutActive = true
                self.isPaused = false
                self.workoutError = nil
            case .paused:
                self.isPaused = true
            case .stopped:
                self.isWorkoutActive = false
                self.isPaused = false
            default:
                break
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed: \(error)")
        DispatchQueue.main.async {
            self.workoutError = "Workout failed: \(error.localizedDescription)"
            self.isWorkoutActive = false
        }
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
        
        // Apply GPS accuracy filtering based on user preference
        let gpsAccuracy = WatchUserPreferences.gpsAccuracy
        
        // Filter based on GPS accuracy setting
        if let accuracyThreshold = gpsAccuracy, accuracyThreshold > 0 {
            // If accuracy threshold is set and location doesn't meet it, skip
            if location.horizontalAccuracy > accuracyThreshold {
                return
            }
        } else if gpsAccuracy == -1 {
            // GPS filtering is off, accept all locations with positive accuracy
            if location.horizontalAccuracy <= 0 {
                return
            }
        } else {
            // Standard (nil) - use dynamic filtering
            // Skip locations with poor accuracy during normal tracking
            if location.horizontalAccuracy > 50 || location.horizontalAccuracy <= 0 {
                return
            }
        }
        
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
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("Location authorization status changed to: \(status.rawValue)")
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
                    remaining.removeAll { $0["id"] as? String == workout["id"] as? String }
                    UserDefaults.standard.set(remaining, forKey: "PendingWorkouts")
                }
            }) { error in
                print("Failed to sync workout: \(error)")
            }
        }
    }
}
