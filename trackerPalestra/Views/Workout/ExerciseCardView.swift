import SwiftUI

struct ExerciseCardView: View {
    @Binding var exercise: WorkoutExerciseSession
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name.uppercased())
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.acidGreen)
                    
                    if exercise.isPR {
                        Label("NUOVO RECORD", systemImage: "trophy.fill")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(.acidGreen)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.acidGreen.opacity(0.2)).cornerRadius(5)
                    }
                }
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "minus.square.fill")
                        .foregroundColor(.red.opacity(0.6))
                        .font(.title2)
                }
            }

            // --- RIPRISTINATE: NOTE SPECIFICHE ESERCIZIO ---
            VStack(alignment: .leading, spacing: 5) {
                Text("NOTE ESERCIZIO / CIRCUITO")
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(.deepPurple)
                
                TextEditor(text: $exercise.exerciseNotes)
                    .frame(minHeight: 50)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.03)))
                    .scrollContentBackground(.hidden)
            }

            // Lista dei Set
            VStack(spacing: 12) {
                ForEach(exercise.sets.indices, id: \.self) { index in
                    HStack(spacing: 20) {
                        Text("\(index + 1)")
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundColor(.acidGreen)
                            .frame(width: 30)

                        VStack(alignment: .center, spacing: 2) {
                            Text("REPS").font(.system(size: 8, weight: .black)).foregroundColor(.deepPurple)
                            TextField("0", value: $exercise.sets[index].reps, format: .number)
                                .keyboardType(.numberPad)
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .multilineTextAlignment(.center).frame(width: 60)
                                .padding(6).background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.05)))
                        }

                        if !exercise.isBodyweight {
                            VStack(alignment: .center, spacing: 2) {
                                Text("KG").font(.system(size: 8, weight: .black)).foregroundColor(.deepPurple)
                                TextField("0.0", value: $exercise.sets[index].weight, format: .number)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                                    .multilineTextAlignment(.center).frame(width: 80)
                                    .padding(6).background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.05)))
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                }
            }

            HStack {
                Button(action: addSet) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("AGGIUNGI SET")
                    }
                    .font(.system(size: 11, weight: .black)).foregroundColor(.customBlack)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Color.acidGreen).cornerRadius(8)
                }
                
                Spacer()
                
                if !exercise.sets.isEmpty {
                    Button(action: { exercise.sets.removeLast() }) {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red.opacity(0.5)).padding(10)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.cardGradient)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .padding(.horizontal, 16)
    }

    private func addSet() {
        let newIndex = exercise.sets.count
        exercise.sets.append(WorkoutSet(id: UUID().uuidString, setIndex: newIndex, reps: exercise.sets.last?.reps ?? 10, weight: exercise.sets.last?.weight ?? 0, isPR: false))
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
