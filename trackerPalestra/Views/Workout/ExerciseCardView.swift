import SwiftUI

struct ExerciseCardView: View {
    @Binding var exercise: WorkoutExerciseSession

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(exercise.name)
                        .font(.headline)
                    if exercise.isPR {
                        Text("★")
                            .foregroundColor(.yellow)
                    }
                    Spacer()
                }

                // Importante: lavoriamo sempre sul binding $exercise
                ForEach(exercise.sets.indices, id: \.self) { index in
                    HStack {
                        Text("Set \(index + 1)")
                            .frame(width: 60, alignment: .leading)

                        TextField(
                            "Reps",
                            value: $exercise.sets[index].reps,
                            format: .number
                        )
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)

                        if !exercise.isBodyweight {
                            TextField(
                                "Kg",
                                value: $exercise.sets[index].weight,
                                format: .number
                            )
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        }

                        if exercise.sets[index].isPR {
                            Text("★")
                                .foregroundColor(.yellow)
                        }
                    }
                }

                HStack {
                    Button("+ Set") {
                        let newIndex = exercise.sets.count
                        exercise.sets.append(
                            WorkoutSet(
                                id: UUID().uuidString,
                                setIndex: newIndex,
                                reps: exercise.sets.last?.reps ?? 8,
                                weight: exercise.sets.last?.weight ?? 0,
                                setNotes: nil,
                                isPR: false
                            )
                        )
                    }

                    if !exercise.sets.isEmpty {
                        Button("- Set") {
                            exercise.sets.removeLast()
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Note esercizio")
                        .font(.subheadline)
                    TextField(
                        "Scrivi note per questo esercizio",
                        text: $exercise.exerciseNotes,
                        axis: .vertical
                    )
                    .lineLimit(1...3)
                    .textFieldStyle(.roundedBorder)
                }
            }
        }
    }
}
