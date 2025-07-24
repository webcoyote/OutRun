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
        ScrollView {
            VStack(spacing: 15) {
                // Workout Type Selection
                VStack(alignment: .leading, spacing: 4) {
                    Text("Workout Type")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                    
                    NavigationLink(destination: WorkoutTypeSelectionView(selectedType: $selectedWorkoutType)) {
                        HStack {
                            Text(selectedWorkoutType.displayName)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .background(Color(UIColor.darkGray))
                    .cornerRadius(8)
                }

                Button(action: {
                    workoutManager.startWorkout(type: selectedWorkoutType)
                }) {
                    Text("Start")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(10)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 20)
                
                if let error = workoutManager.workoutError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("OutRun")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gear")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct WorkoutTypeSelectionView: View {
    @Binding var selectedType: WorkoutType
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        List {
            ForEach(WorkoutType.allCases, id: \.self) { type in
                Button(action: {
                    selectedType = type
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Text(type.displayName)
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedType == type {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .navigationTitle("Workout Type")
        .navigationBarTitleDisplayMode(.inline)
    }
}
