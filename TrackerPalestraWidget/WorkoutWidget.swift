import WidgetKit
import SwiftUI

struct WorkoutProvider: TimelineProvider {
    func placeholder(in context: Context) -> WorkoutEntry {
        WorkoutEntry(date: Date(), planName: "Pettorali", dayLabel: "Giorno A")
    }

    func getSnapshot(in context: Context, completion: @escaping (WorkoutEntry) -> Void) {
        let entry = WorkoutEntry(date: Date(), planName: "Scheda Pro", dayLabel: "Giorno B")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        // Qui caricheresti l'ultimo piano salvato da UserDefaults condiviso
        let entry = WorkoutEntry(date: Date(), planName: "Leg Day", dayLabel: "Sessione C")
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct WorkoutEntry: TimelineEntry {
    let date: Date
    let planName: String
    let dayLabel: String
}

struct WorkoutWidgetEntryView : View {
    var entry: WorkoutProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryRectangular:
            // Design per Lock Screen (Orizzontale)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Image(systemName: "dumbbell.fill")
                    Text("NEXT WORKOUT").font(.system(size: 10, weight: .black))
                }
                Text(entry.planName)
                    .font(.headline)
                    .widgetAccentable() // Permette al colore del Lock Screen di applicarsi
                Text(entry.dayLabel)
                    .font(.caption)
                    .opacity(0.8)
            }
        case .systemSmall:
            // Design per Home Screen (Quadrato)
            VStack(alignment: .leading) {
                Text("OGGI")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.acidGreen)
                Spacer()
                Text(entry.planName).fontWeight(.bold)
                Text(entry.dayLabel).font(.caption).foregroundColor(.secondary)
            }
            .padding()
            .containerBackground(Color.customBlack, for: .widget)
        default:
            Text(entry.planName)
        }
    }
}

@main
struct WorkoutWidget: Widget {
    let kind: String = "WorkoutWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WorkoutProvider()) { entry in
            WorkoutWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Prossimo Allenamento")
        .description("Vedi subito cosa devi allenare oggi.")
        .supportedFamilies([.accessoryRectangular, .systemSmall])
    }
}
