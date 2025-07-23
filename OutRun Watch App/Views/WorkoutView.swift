//
//  WorkoutView.swift
//  OutRun Watch App
//
//  Created on 2025-07-23.
//

import SwiftUI

struct WorkoutView: View {
    @EnvironmentObject var workoutManager: WatchWorkoutManager
    @State private var showEndConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Text(workoutManager.workoutType.displayName)
                        .font(.headline)
                    Spacer()
                    
                    if workoutManager.isPaused {
                        Image(systemName: "pause.circle.fill")
                            .foregroundColor(.yellow)
                    } else {
                        Image(systemName: "circle.fill")
                            .foregroundColor(.green)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    MetricView(title: "Duration", value: workoutManager.formattedDuration)
                    MetricView(title: "Distance", value: workoutManager.formattedDistance)
                    MetricView(title: "Pace", value: workoutManager.formattedPace)
                    
                    if let heartRate = workoutManager.heartRate {
                        MetricView(title: "Heart Rate", value: "\(Int(heartRate)) BPM")
                    }
                }
                
                HStack(spacing: 20) {
                    Button(action: {
                        workoutManager.togglePause()
                    }) {
                        Image(systemName: workoutManager.isPaused ? "play.fill" : "pause.fill")
                            .font(.title2)
                            .frame(width: 60, height: 60)
                            .background(Color.orange)
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        showEndConfirmation = true
                    }) {
                        Image(systemName: "stop.fill")
                            .font(.title2)
                            .frame(width: 60, height: 60)
                            .background(Color.red)
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.top)
            }
            .padding()
        }
        .navigationBarHidden(true)
        .alert(isPresented: $showEndConfirmation) {
            Alert(
                title: Text("End Workout?"),
                message: Text("Are you sure you want to end this workout?"),
                primaryButton: .destructive(Text("End")) {
                    workoutManager.endWorkout()
                },
                secondaryButton: .cancel()
            )
        }
    }
}

struct MetricView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
        }
    }
}