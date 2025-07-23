//
//  OutRunApp.swift
//  OutRun Watch App
//
//  Created on 2025-07-23.
//

import SwiftUI

@main
struct OutRunWatchApp: App {
    @StateObject private var workoutManager = WatchWorkoutManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(workoutManager)
        }
    }
}