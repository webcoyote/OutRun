//
//  SettingsView.swift
//  OutRun Watch App
//
//  Created by Assistant on 1/24/25.
//

import SwiftUI

struct SettingsView: View {
    @State private var selectedDistanceUnit = WatchUserPreferences.distanceUnit
    @State private var selectedAltitudeUnit = WatchUserPreferences.altitudeUnit
    @State private var selectedGPSAccuracy = WatchUserPreferences.gpsAccuracy
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Distance Units Section
                VStack(alignment: .leading, spacing: 4) {
                    Text("Distance Units")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                    
                    NavigationLink(destination: DistanceUnitSelectionView(selectedUnit: $selectedDistanceUnit)) {
                        HStack {
                            Text(selectedDistanceUnit.displayName)
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
                
                // Altitude Units Section
                VStack(alignment: .leading, spacing: 4) {
                    Text("Altitude Units")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                    
                    NavigationLink(destination: AltitudeUnitSelectionView(selectedUnit: $selectedAltitudeUnit)) {
                        HStack {
                            Text(selectedAltitudeUnit.displayName)
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
                
                // GPS Accuracy Section
                VStack(alignment: .leading, spacing: 4) {
                    Text("GPS Accuracy")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                    
                    NavigationLink(destination: GPSAccuracySelectionView(selectedAccuracy: $selectedGPSAccuracy)) {
                        HStack {
                            Text(gpsAccuracyDescription(for: selectedGPSAccuracy))
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
            }
            .padding(.horizontal)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            selectedDistanceUnit = WatchUserPreferences.distanceUnit
            selectedAltitudeUnit = WatchUserPreferences.altitudeUnit
            selectedGPSAccuracy = WatchUserPreferences.gpsAccuracy
        }
    }
    
    private func gpsAccuracyDescription(for accuracy: Double?) -> String {
        switch accuracy {
        case nil:
            return "Standard"
        case 20:
            return "High"
        case 30:
            return "Acceptable"
        case 50:
            return "Last Resort"
        case -1:
            return "Off"
        default:
            return "Standard"
        }
    }
}

struct DistanceUnitSelectionView: View {
    @Binding var selectedUnit: DistanceUnit
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        List {
            ForEach(DistanceUnit.allCases, id: \.self) { unit in
                Button(action: {
                    selectedUnit = unit
                    WatchUserPreferences.distanceUnit = unit
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Text(unit.displayName)
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedUnit == unit {
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
        .navigationTitle("Distance Units")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AltitudeUnitSelectionView: View {
    @Binding var selectedUnit: AltitudeUnit
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        List {
            ForEach(AltitudeUnit.allCases, id: \.self) { unit in
                Button(action: {
                    selectedUnit = unit
                    WatchUserPreferences.altitudeUnit = unit
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Text(unit.displayName)
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedUnit == unit {
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
        .navigationTitle("Altitude Units")
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
                                .foregroundColor(.green)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
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
