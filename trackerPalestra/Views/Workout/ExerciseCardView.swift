import SwiftUI

struct ExerciseCardView: View {
    @Binding var exercise: WorkoutExerciseSession
    @EnvironmentObject var viewModel: MainViewModel
    var onDelete: () -> Void

    // Recupera l'ultimo massimale storico escludendo la sessione corrente
    private var lastMaxWeight: Double {
        viewModel.workoutHistory
            .filter { $0.id != exercise.id } // Importante: non confrontare con se stesso
            .flatMap { $0.exercises }
            .filter { viewModel.normalizeName($0.name) == viewModel.normalizeName(exercise.name) }
            .flatMap { $0.sets }
            .map { $0.weight }
            .max() ?? 0
    }

    // Dati dell'ultima volta per i Ghost Sets
    private var lastSessionData: WorkoutExerciseSession? {
        viewModel.workoutHistory
            .flatMap { $0.exercises }
            .first { viewModel.normalizeName($0.name) == viewModel.normalizeName(exercise.name) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name.uppercased())
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.acidGreen)
                    
                    HStack(spacing: 8) {
                        // Badge Massimale Storico
                        if lastMaxWeight > 0 {
                            Text("BEST: \(lastMaxWeight, specifier: "%.1f") KG")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color.white.opacity(0.1)).cornerRadius(5)
                        }
                        
                        // Badge NUOVO RECORD (Trophy)
                        if exercise.isPR {
                            Label("NEW RECORD", systemImage: "trophy.fill")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.black)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color.acidGreen).cornerRadius(5)
                        }
                    }
                }
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "minus.square.fill").foregroundColor(.red.opacity(0.6)).font(.title2)
                }
            }

            // Note Esercizio
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

            // Lista dei Set con Ghost suggeriti
            VStack(spacing: 12) {
                ForEach(exercise.sets.indices, id: \.self) { index in
                    let ghostSet = (lastSessionData?.sets.indices.contains(index) ?? false) ? lastSessionData?.sets[index] : nil
                    
                    HStack(spacing: 20) {
                        Text("\(index + 1)")
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundColor(.acidGreen)
                            .frame(width: 30)

                        VStack(alignment: .center, spacing: 2) {
                            Text("REPS").font(.system(size: 8, weight: .black)).foregroundColor(.deepPurple)
                            TextField(ghostSet != nil ? "\(ghostSet!.reps)" : "0",
                                      value: Binding(
                                        get: { exercise.sets[index].reps == 0 ? nil : Double(exercise.sets[index].reps) },
                                        set: { exercise.sets[index].reps = Int($0 ?? 0) }
                                      ), format: .number)
                                .keyboardType(.numberPad)
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .multilineTextAlignment(.center).frame(width: 60)
                                .padding(6).background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.05)))
                        }

                        if !exercise.isBodyweight {
                            VStack(alignment: .center, spacing: 2) {
                                Text("KG").font(.system(size: 8, weight: .black)).foregroundColor(.deepPurple)
                                TextField(ghostSet != nil ? "\(ghostSet!.weight, specifier: "%.1f")" : "0.0",
                                          value: Binding(
                                            get: { exercise.sets[index].weight == 0 ? nil : exercise.sets[index].weight },
                                            set: { exercise.sets[index].weight = $0 ?? 0 }
                                          ), format: .number)
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
                        Image(systemName: "trash.fill").foregroundColor(.red.opacity(0.5)).padding(10)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.cardGradient)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        // AGGIORNAMENTO DINAMICO DEL BADGE RECORD
        .onChange(of: exercise.sets.map { $0.weight }) { _ in
            let currentMax = exercise.sets.map { $0.weight }.max() ?? 0
            // Se il peso attuale è maggiore del massimo storico (o se è il primo allenamento)
            exercise.isPR = currentMax > lastMaxWeight && currentMax > 0
        }
    }

    private func addSet() {
        let newIndex = exercise.sets.count
        let lastSet = exercise.sets.last
        exercise.sets.append(WorkoutSet(id: UUID().uuidString, setIndex: newIndex, reps: lastSet?.reps ?? 10, weight: lastSet?.weight ?? 0, isPR: false))
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
