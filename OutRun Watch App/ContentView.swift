//
//  ContentView.swift
//  OutRun Watch App
//
//  Created on 2025-07-23.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var workoutManager: WatchWorkoutManager
    
    var body: some View {
        NavigationStack {
            if workoutManager.isWorkoutActive {
                WorkoutView()
            } else {
                StartView()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(WatchWorkoutManager())
    }
}