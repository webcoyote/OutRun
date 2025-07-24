//
//  SettingsView.swift
//  OutRun Watch App
//
//  Created by Assistant on 1/24/25.
//

import SwiftUI

struct SettingsView: View {
    @State private var useKilometers = WatchUserPreferences.useKilometers
    @State private var selectedGPSAccuracy = WatchUserPreferences.gpsAccuracy
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Distance Units Section
                VStack(alignment: .leading, spacing: 4) {
                    Text("Distance Units")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Picker("Distance Units", selection: $useKilometers) {
                        Text("Kilometers").tag(true)
                        Text("Miles").tag(false)
                    }
                    .pickerStyle(.automatic)
                    .onChange(of: useKilometers) { newValue in
                        WatchUserPreferences.useKilometers = newValue
                    }
                }
                
                Divider()
                
                // GPS Accuracy Section
                VStack(alignment: .leading, spacing: 4) {
                    Text("GPS Accuracy")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    NavigationLink(destination: GPSAccuracySelectionView(selectedAccuracy: $selectedGPSAccuracy)) {
                        HStack {
                            Text(WatchUserPreferences.gpsAccuracyDescription)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct GPSAccuracySelectionView: View {
    @Binding var selectedAccuracy: Double?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        List {
            ForEach(WatchUserPreferences.gpsAccuracyOptions, id: \.description) { option in
                Button(action: {
                    selectedAccuracy = option.value
                    WatchUserPreferences.gpsAccuracy = option.value
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Text(option.description)
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedAccuracy == option.value {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .navigationTitle("GPS Accuracy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
}