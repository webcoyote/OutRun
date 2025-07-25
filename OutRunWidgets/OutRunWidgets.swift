//
//  OutRunWidgets.swift
//  OutRun Watch App
//
//  Created on 2025-07-25.
//

import WidgetKit
import SwiftUI

struct OutRunWidgetsProvider: TimelineProvider {
    func placeholder(in context: Context) -> OutRunEntry {
        OutRunEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (OutRunEntry) -> Void) {
        let entry = OutRunEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<OutRunEntry>) -> Void) {
        let entry = OutRunEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct OutRunEntry: TimelineEntry {
    let date: Date
    var lastWorkoutDate: Date?
    var totalDistance: Double = 0.0
    var weeklyRunCount: Int = 0
}

struct OutRunWidgetsView: View {
    var entry: OutRunWidgetsProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "figure.run")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }

        case .accessoryRectangular:
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "figure.run")
                        .font(.system(size: 16))
                    Text("OutRun")
                        .font(.headline)
                }
                Text("Track your run")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

        case .accessoryInline:
            HStack {
                Image(systemName: "figure.run")
                    .font(.caption)
                Text("OutRun")
            }

        case .accessoryCorner:
            Image(systemName: "figure.run")
                .font(.system(size: 32))

        @unknown default:
            Text("OutRun")
        }
    }
}

@main
struct OutRunWidgets: Widget {
    let kind: String = "OutRunWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OutRunWidgetsProvider()) { entry in
            OutRunWidgetsView(entry: entry)
        }
        .configurationDisplayName("OutRun")
        .description("Quick access to track your runs")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCorner
        ])
    }
}

struct OutRunWidgets_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            OutRunWidgetsView(entry: OutRunEntry(date: Date()))
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))

            OutRunWidgetsView(entry: OutRunEntry(date: Date()))
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))

            OutRunWidgetsView(entry: OutRunEntry(date: Date()))
                .previewContext(WidgetPreviewContext(family: .accessoryInline))
        }
    }
}
