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
        ZStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(workoutManager.formattedDuration)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(workoutManager.isPaused ? .gray : .yellow)
                
                HStack(spacing: 4) {
                    Text(workoutManager.heartRate != nil ? "\(Int(workoutManager.heartRate!))" : "--")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Text(workoutManager.formattedDistance)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text(workoutManager.formattedPace)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
            VStack {
                Spacer()
                
                HStack(spacing: 30) {
                    Button(action: {
                        workoutManager.togglePause()
                    }) {
                        Image(systemName: workoutManager.isPaused ? "play.fill" : "pause.fill")
                            .font(.body)
                            .frame(width: 44, height: 44)
                            .background(Color.orange)
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        showEndConfirmation = true
                    }) {
                        Image(systemName: "stop.fill")
                            .font(.body)
                            .frame(width: 44, height: 44)
                            .background(Color.red)
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.bottom, 4)
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .overlay(
            Group {
                if showEndConfirmation {
                    Color.black
                        .opacity(0.8)
                        .edgesIgnoringSafeArea(.all)
                }
            }
        )
        .navigationTitle {
            HStack {
                if workoutManager.isPaused {
                    Image(systemName: "pause.circle.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                } else {
                    Image(systemName: "circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
                Text(workoutManager.workoutType.displayName)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
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

