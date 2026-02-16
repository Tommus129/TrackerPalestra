import SwiftUI

struct DayDetailView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @Binding var day: WorkoutPlanDay

    @State private var newExerciseName: String = ""
    @State private var newExerciseSets: Int = 3
    @State private var newExerciseReps: Int = 8
    @State private var newExerciseIsBodyweight: Bool = false
    @State private var newExerciseNotes: String = ""

    var suggestions: [String] {
        if newExerciseName.isEmpty { return [] }
        return viewModel.exerciseNames.filter {
            $0.lowercased().contains(newExerciseName.lowercased()) &&
            $0.lowercased() != newExerciseName.lowercased()
        }
    }

    var body: some View {
        ZStack {
            Color.customBlack.ignoresSafeArea()
            List {
                Section {
                    TextField("Nome giorno", text: $day.label).foregroundColor(.white)
                } header: { Text("NOME GIORNO").foregroundColor(.acidGreen) }
                .listRowBackground(Color.white.opacity(0.05))

                Section("ESERCIZI IN LISTA") {
                    ForEach(day.exercises) { exercise in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(exercise.name.uppercased()).font(.headline).foregroundColor(.white)
                                Spacer()
                                Text("\(exercise.defaultSets)x\(exercise.defaultReps)").font(.caption).foregroundColor(.secondary)
                            }
                            if !exercise.notes.isEmpty {
                                Text(exercise.notes).font(.caption2).italic().foregroundColor(.acidGreen.opacity(0.8))
                            }
                        }
                    }
                    .onDelete { day.exercises.remove(atOffsets: $0) }
                }
                .listRowBackground(Color.white.opacity(0.05))

                Section("NUOVO ESERCIZIO / CIRCUITO") {
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("Nome esercizio", text: $newExerciseName).foregroundColor(.white)
                        if !suggestions.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(suggestions, id: \.self) { sug in
                                        Button(sug) { newExerciseName = sug }.buttonStyle(.bordered).tint(.acidGreen).controlSize(.mini)
                                    }
                                }
                            }
                        }
                        TextField("Descrizione circuito (opzionale)", text: $newExerciseNotes, axis: .vertical)
                            .font(.caption).foregroundColor(.white).padding(8).background(Color.white.opacity(0.05)).cornerRadius(8)
                    }
                    HStack {
                        Stepper("Serie: \(newExerciseSets)", value: $newExerciseSets, in: 1...15)
                        Stepper("Reps: \(newExerciseReps)", value: $newExerciseReps, in: 1...50)
                    }.foregroundColor(.white)
                    Toggle("Corpo Libero", isOn: $newExerciseIsBodyweight).foregroundColor(.white)
                    Button(action: addExercise) {
                        Label("AGGIUNGI", systemImage: "plus.circle.fill").fontWeight(.bold).foregroundColor(.customBlack)
                    }.buttonStyle(.borderedProminent).tint(.acidGreen).disabled(newExerciseName.isEmpty)
                }
                .listRowBackground(Color.white.opacity(0.05))
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(day.label)
    }

    private func addExercise() {
        let name = viewModel.normalizeName(newExerciseName)
        guard !name.isEmpty else { return }
        let ex = WorkoutPlanExercise(id: UUID().uuidString, name: name, defaultSets: newExerciseSets, defaultReps: newExerciseReps, isBodyweight: newExerciseIsBodyweight, notes: newExerciseNotes)
        day.exercises.append(ex)
        newExerciseName = ""; newExerciseNotes = ""
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
