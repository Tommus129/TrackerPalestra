import SwiftUI

struct WorkoutSessionDetailView: View {
    let session: WorkoutSession

    var body: some View {
        List {
            Section(header: Text("Info")) {
                Text("Data: \(formatDate(session.date))")
                Text("Piano: \(session.planId)")
                Text("Giorno: \(session.dayId)")
            }

            Section(header: Text("Note")) {
                if session.notes.isEmpty {
                    Text("Nessuna nota")
                        .foregroundColor(.secondary)
                } else {
                    Text(session.notes)
                }
            }

            ForEach(session.exercises) { exercise in
                Section(header: Text(exercise.name)) {
                    ForEach(exercise.sets) { set in
                        HStack {
                            Text("Set \(set.setIndex + 1)")
                            Spacer()
                            Text("\(set.reps) reps")
                            if !exercise.isBodyweight {
                                Text("• \(set.weight, specifier: "%.1f") kg")
                            }
                        }
                    }

                    if !exercise.exerciseNotes.isEmpty {
                        Text(exercise.exerciseNotes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Dettaglio")
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}
