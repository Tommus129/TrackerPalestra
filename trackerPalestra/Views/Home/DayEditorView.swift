import SwiftUI

struct DayEditorView: View {
    @Binding var day: WorkoutPlanDay
    var onDelete: () -> Void

    @State private var newExerciseName: String = ""
    @State private var newExerciseSets: Int = 3
    @State private var newExerciseReps: Int = 8
    @State private var newExerciseIsBodyweight: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Nome giorno + elimina giorno
            HStack {
                TextField("Nome giorno", text: $day.label)
                    .font(.headline)

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                }
            }

            // Lista esercizi
            if day.exercises.isEmpty {
                Text("Nessun esercizio")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                ForEach($day.exercises) { $exercise in
                    HStack {
                        VStack(alignment: .leading) {
                            TextField("Nome esercizio", text: $exercise.name)
                                .font(.subheadline)
                            Text("\(exercise.defaultSets) x \(exercise.defaultReps)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if exercise.isBodyweight {
                            Text("BW")
                                .font(.caption)
                                .padding(4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                        }
                        Button(role: .destructive) {
                            deleteExercise(exercise)
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                    }
                }
            }

            Divider()
                .padding(.vertical, 4)

            // Aggiunta nuovo esercizio
            VStack(alignment: .leading, spacing: 4) {
                Text("Aggiungi esercizio")
                    .font(.subheadline)

                TextField("Nome esercizio", text: $newExerciseName)

                HStack {
                    Stepper("Serie: \(newExerciseSets)", value: $newExerciseSets, in: 1...10)
                    Stepper("Reps: \(newExerciseReps)", value: $newExerciseReps, in: 1...20)
                }

                Toggle("Bodyweight", isOn: $newExerciseIsBodyweight)

                Button {
                    addExercise()
                } label: {
                    Label("Aggiungi", systemImage: "plus.circle.fill")
                }
                .disabled(newExerciseName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(.vertical, 4)
    }

    private func addExercise() {
        let trimmedName = newExerciseName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let ex = WorkoutPlanExercise(
            id: UUID().uuidString,
            name: trimmedName,
            defaultSets: newExerciseSets,
            defaultReps: newExerciseReps,
            isBodyweight: newExerciseIsBodyweight
        )

        day.exercises.append(ex)

        newExerciseName = ""
        newExerciseSets = 3
        newExerciseReps = 8
        newExerciseIsBodyweight = false
    }

    private func deleteExercise(_ exercise: WorkoutPlanExercise) {
        if let idx = day.exercises.firstIndex(where: { $0.id == exercise.id }) {
            day.exercises.remove(at: idx)
        }
    }
}
