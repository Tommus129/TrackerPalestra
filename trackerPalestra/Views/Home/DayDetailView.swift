import SwiftUI

struct DayDetailView: View {
    @EnvironmentObject var viewModel: MainViewModel

    @Binding var day: WorkoutPlanDay

    @State private var newExerciseName: String = ""
    @State private var newExerciseSets: Int = 3
    @State private var newExerciseReps: Int = 8
    @State private var newExerciseIsBodyweight: Bool = false

    var body: some View {
        List {
            Section {
                TextField("Nome giorno", text: $day.label)
            }

            Section("Esercizi") {
                ForEach(day.exercises.indices, id: \.self) { idx in
                    HStack {
                        VStack(alignment: .leading) {
                            TextField(
                                "Nome esercizio",
                                text: $day.exercises[idx].name
                            )
                            .font(.subheadline)

                            Text("\(day.exercises[idx].defaultSets) x \(day.exercises[idx].defaultReps)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if day.exercises[idx].isBodyweight {
                            Text("BW")
                                .font(.caption)
                                .padding(4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
                .onDelete { offsets in
                    day.exercises.remove(atOffsets: offsets)
                }
            }

            Section("Aggiungi esercizio") {
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
        .navigationTitle(day.label)
    }

    // MARK: - Azioni esercizi

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
}
