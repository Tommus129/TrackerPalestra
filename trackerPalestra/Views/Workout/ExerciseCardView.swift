import SwiftUI

struct ExerciseCardView: View {
    @Binding var exercise: WorkoutExerciseSession
    @EnvironmentObject var viewModel: MainViewModel
    var onDelete: () -> Void
    /// Recupero in secondi da avviare automaticamente al check dell'ultimo set.
    var restSeconds: Int = 60
    /// Callback per avviare il timer nella parent view
    var onStartRest: ((Int) -> Void)? = nil
    
    // Tema colore
    var accentColor: Color = .acidGreen

    private var lastMaxWeight: Double {
        viewModel.workoutHistory
            .filter { $0.id != exercise.id }
            .flatMap { $0.exercises }
            .filter { viewModel.normalizeName($0.name) == viewModel.normalizeName(exercise.name) }
            .flatMap { $0.sets }
            .map { $0.weight }
            .max() ?? 0
    }

    private var lastSessionData: WorkoutExerciseSession? {
        viewModel.workoutHistory
            .flatMap { $0.exercises }
            .first { viewModel.normalizeName($0.name) == viewModel.normalizeName(exercise.name) }
    }

    private var lastSessionNotes: String? { lastSessionData?.exerciseNotes }

    // Toggle per mostrare/nascondere le note, rendendo la UI più pulita
    @State private var showNotes = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(exercise.name.uppercased())
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(accentColor)
                    
                    HStack(spacing: 8) {
                        if lastMaxWeight > 0 {
                            Text("BEST: \(lastMaxWeight, specifier: "%.1f") KG")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color.white.opacity(0.1)).cornerRadius(6)
                        }
                        if exercise.isPR {
                            Label("PR", systemImage: "trophy.fill")
                                .font(.system(size: 10, weight: .black)).foregroundColor(.black)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color.acidGreen).cornerRadius(6)
                        }
                    }
                }
                Spacer()
                
                HStack(spacing: 12) {
                    restBadge
                    
                    Menu {
                        Button("Aggiungi Nota", systemImage: "note.text") {
                            withAnimation { showNotes.toggle() }
                        }
                        Button("Elimina Esercizio", systemImage: "trash", role: .destructive) {
                            onDelete()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            // MARK: - Notes
            if showNotes || !exercise.exerciseNotes.isEmpty || (lastSessionNotes != nil && !lastSessionNotes!.isEmpty) {
                VStack(alignment: .leading, spacing: 12) {
                    if let previousNotes = lastSessionNotes, !previousNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("NOTE PRECEDENTI").font(.system(size: 9, weight: .bold)).foregroundColor(.white.opacity(0.4))
                            Text(previousNotes)
                                .font(.system(size: 12)).foregroundColor(.white.opacity(0.7)).italic()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.03)))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("NOTE SESSIONE").font(.system(size: 9, weight: .bold)).foregroundColor(accentColor.opacity(0.7))
                        TextEditor(text: $exercise.exerciseNotes)
                            .frame(minHeight: 40)
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                            .padding(6)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.2)))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.05), lineWidth: 1))
                            .scrollContentBackground(.hidden)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }

            // MARK: - Sets Table
            VStack(spacing: 0) {
                // Table Header
                HStack {
                    Text("SET").frame(width: 30, alignment: .center)
                    Spacer()
                    Text("REPS").frame(width: 70, alignment: .center)
                    if !exercise.isBodyweight {
                        Spacer()
                        Text("KG").frame(width: 80, alignment: .center)
                    }
                    Spacer()
                    Image(systemName: "checkmark").frame(width: 32, alignment: .center)
                }
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.white.opacity(0.4))
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
                
                // Rows
                ForEach(exercise.sets.indices, id: \.self) { index in
                    let isCompleted = exercise.sets[index].isCompleted
                    let ghostSet = (lastSessionData?.sets.indices.contains(index) ?? false) ? lastSessionData?.sets[index] : nil
                    
                    HStack {
                        // Set Number
                        Text("\(index + 1)")
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundColor(isCompleted ? accentColor.opacity(0.5) : accentColor)
                            .frame(width: 30, alignment: .center)

                        Spacer()

                        // Reps Input
                        TextField(ghostSet != nil ? "\(ghostSet!.reps)" : "0",
                                  value: Binding(
                                    get: { exercise.sets[index].reps == 0 ? nil : Double(exercise.sets[index].reps) },
                                    set: { exercise.sets[index].reps = Int($0 ?? 0) }
                                  ), format: .number)
                            .keyboardType(.numberPad)
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(isCompleted ? .white.opacity(0.5) : .white)
                            .multilineTextAlignment(.center)
                            .frame(width: 70, height: 40)
                            .background(RoundedRectangle(cornerRadius: 8).fill(isCompleted ? Color.clear : Color.white.opacity(0.05)))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(isCompleted ? Color.clear : Color.white.opacity(0.1), lineWidth: 1))

                        if !exercise.isBodyweight {
                            Spacer()
                            // KG Input
                            TextField(ghostSet != nil ? "\(ghostSet!.weight, specifier: "%.1f")" : "0.0",
                                      value: Binding(
                                        get: { exercise.sets[index].weight == 0 ? nil : exercise.sets[index].weight },
                                        set: { exercise.sets[index].weight = $0 ?? 0 }
                                      ), format: .number)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundColor(isCompleted ? .white.opacity(0.5) : .white)
                                .multilineTextAlignment(.center)
                                .frame(width: 80, height: 40)
                                .background(RoundedRectangle(cornerRadius: 8).fill(isCompleted ? Color.clear : Color.white.opacity(0.05)))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(isCompleted ? Color.clear : Color.white.opacity(0.1), lineWidth: 1))
                        }

                        Spacer()

                        // Check Button
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                exercise.sets[index].isCompleted.toggle()
                            }
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            if exercise.sets[index].isCompleted {
                                onStartRest?(restSeconds)
                            }
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isCompleted ? accentColor.opacity(0.15) : Color.white.opacity(0.03))
                                    .frame(width: 44, height: 40)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(isCompleted ? accentColor : Color.white.opacity(0.15), lineWidth: 2)
                                    )
                                
                                if isCompleted {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .black))
                                        .foregroundColor(accentColor)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 6)
                    .background(isCompleted ? accentColor.opacity(0.03) : Color.clear)
                }
            }

            // MARK: - Footer Actions
            HStack {
                Button(action: addSet) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("AGGIUNGI SET")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(accentColor)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(RoundedRectangle(cornerRadius: 8).fill(accentColor.opacity(0.1)))
                }
                
                Spacer()
                
                if exercise.sets.count > 1 {
                    Button(action: { 
                        withAnimation { exercise.sets.removeLast() }
                    }) {
                        Text("RIMUOVI SET")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.red.opacity(0.7))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.red.opacity(0.1)))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color.cardGradient)
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.05), lineWidth: 1.5))
        .contentShape(Rectangle())
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onChange(of: exercise.sets.map { $0.weight }) { _ in
            let currentMax = exercise.sets.map { $0.weight }.max() ?? 0
            exercise.isPR = currentMax > lastMaxWeight && currentMax > 0
        }
        .onAppear { prefillGhostWeights() }
    }

    // Badge recupero
    @ViewBuilder
    private var restBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "timer")
                .font(.system(size: 10, weight: .bold))
            Text(formatRest(restSeconds))
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundColor(.white.opacity(0.7))
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Color.white.opacity(0.08))
        .cornerRadius(8)
    }

    private func formatRest(_ s: Int) -> String {
        if s < 60 { return "\(s)s" }
        let m = s / 60; let sec = s % 60
        return sec == 0 ? "\(m)m" : "\(m)m \(sec)s"
    }

    private func addSet() {
        let newIndex = exercise.sets.count
        let lastSet = exercise.sets.last
        exercise.sets.append(WorkoutSet(id: UUID().uuidString, setIndex: newIndex,
            reps: lastSet?.reps ?? 10, weight: lastSet?.weight ?? 0, isPR: false, isCompleted: false))
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func prefillGhostWeights() {
        guard let lastData = lastSessionData else { return }
        for index in exercise.sets.indices {
            if index < lastData.sets.count {
                let ghostSet = lastData.sets[index]
                if exercise.sets[index].reps == 0 { exercise.sets[index].reps = ghostSet.reps }
                if exercise.sets[index].weight == 0 && !exercise.isBodyweight { exercise.sets[index].weight = ghostSet.weight }
            }
        }
    }
}
