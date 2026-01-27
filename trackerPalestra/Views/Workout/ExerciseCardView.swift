import SwiftUI

struct ExerciseCardView: View {
    @Binding var exercise: WorkoutExerciseSession
    var onDelete: () -> Void // Closure per gestire l'eliminazione

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Header: Nome + PR + Tasto Elimina
            HStack {
                Text(exercise.name.uppercased())
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.heavy)
                    .foregroundColor(.acidGreen)
                
                if exercise.isPR {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.acidGreen)
                }
                
                Spacer()
                
                // TASTO ELIMINA ESERCIZIO
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red.opacity(0.7))
                        .font(.title3)
                }
            }

            // Visualizzazione Note Tecniche (se presenti dalla scheda o dal circuito)
            if !exercise.exerciseNotes.isEmpty {
                Text(exercise.exerciseNotes)
                    .font(.caption)
                    .italic()
                    .foregroundColor(.white.opacity(0.7))
                    .padding(8)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
            }

            // Lista dei Set
            VStack(spacing: 10) {
                ForEach(exercise.sets.indices, id: \.self) { index in
                    HStack(spacing: 15) {
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(.customBlack)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Color.acidGreen))
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text("REPS")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.deepPurple)
                            TextField("0", value: $exercise.sets[index].reps, format: .number)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.plain)
                                .foregroundColor(.white)
                        }
                        
                        if !exercise.isBodyweight {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("KG")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.deepPurple)
                                TextField("0.0", value: $exercise.sets[index].weight, format: .number)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.plain)
                                    .foregroundColor(.white)
                            }
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(Color.customBlack.opacity(0.4))
                    .cornerRadius(10)
                }
            }

            // Azioni Set
            HStack {
                Button(action: addSet) {
                    Label("SET", systemImage: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.acidGreen)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.acidGreen.opacity(0.1))
                .cornerRadius(8)
                
                if !exercise.sets.isEmpty {
                    Button(action: { exercise.sets.removeLast() }) {
                        Image(systemName: "trash").foregroundColor(.red.opacity(0.7))
                    }
                    .padding(8)
                }
            }
        }
        .padding()
        .background(Color.deepPurple.opacity(0.15))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.deepPurple.opacity(0.3), lineWidth: 1))
    }

    private func addSet() {
        let newIndex = exercise.sets.count
        exercise.sets.append(WorkoutSet(
            id: UUID().uuidString,
            setIndex: newIndex,
            reps: exercise.sets.last?.reps ?? 10,
            weight: exercise.sets.last?.weight ?? 0,
            isPR: false
        ))
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
