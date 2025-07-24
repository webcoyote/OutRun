//
//  StartView.swift
//  OutRun Watch App
//
//  Created on 2025-07-23.
//

import SwiftUI

struct StartView: View {
    @EnvironmentObject var workoutManager: WatchWorkoutManager
    @State private var selectedWorkoutType: WorkoutType = .running
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gear")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Text("OutRun")
                .font(.title2)
                .fontWeight(.bold)
            
            Picker("Workout Type", selection: $selectedWorkoutType) {
                ForEach(WorkoutType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(height: 100)
            
            Button(action: {
                workoutManager.startWorkout(type: selectedWorkoutType)
            }) {
                Text("Start")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .navigationBarHidden(true)
    }
}