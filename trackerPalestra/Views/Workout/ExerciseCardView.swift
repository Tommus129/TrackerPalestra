import SwiftUI

struct ExerciseCardView: View {
    @Binding var exercise: WorkoutExerciseSession
    @EnvironmentObject var viewModel: MainViewModel
    var onDelete: () -> Void
    var restSeconds: Int = 60
    var onStartRest: ((Int) -> Void)? = nil
    var accentColor: Color = .acidGreen
    var isInsideGroup: Bool = false

    @State private var cachedLastMaxWeight: Double = 0
    @State private var cachedLastSessionData: WorkoutExerciseSession? = nil
    @State private var showNotes = false

    private var lastSessionNotes: String? { cachedLastSessionData?.exerciseNotes }

    /// Peso massimo corrente tra tutti i set — estratto in computed property
    /// per evitare il timeout del type-checker quando usato in .onChange.
    private var currentMaxWeight: Double {
        exercise.sets.map { $0.weight }.max() ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView
            notesView
            setsTableView
            footerView
        }
        .background(Color.cardGradient)
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.05), lineWidth: 1.5))
        .contentShape(Rectangle())
        .padding(.trailing, isInsideGroup ? 16 : 0)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        // FIX P1: currentMaxWeight è una computed property atomica (Double),
        // il type-checker non deve più inferire la catena inline.
        .onChange(of: currentMaxWeight) { newMax in
            exercise.isPR = newMax > cachedLastMaxWeight && newMax > 0
        }
        .onAppear {
            updateHistoryCache()
            prefillGhostWeights()
        }
        .onChange(of: viewModel.workoutHistory.count) { _ in
            updateHistoryCache()
        }
    }

    // MARK: - Cache Update

    private func updateHistoryCache() {
        let normalized = viewModel.normalizeName(exercise.name)
        var foundMax: Double = 0
        var foundSession: WorkoutExerciseSession? = nil
        for session in viewModel.workoutHistory {
            if let ex = session.exercises.first(where: { viewModel.normalizeName($0.name) == normalized }) {
                if foundSession == nil { foundSession = ex }
                let sessionMax = ex.sets.map { $0.weight }.max() ?? 0
                if sessionMax > foundMax { foundMax = sessionMax }
            }
        }
        cachedLastMaxWeight = foundMax
        cachedLastSessionData = foundSession
    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(exercise.name.uppercased())
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(accentColor)

                HStack(spacing: 8) {
                    if cachedLastMaxWeight > 0 {
                        Text("BEST: \(cachedLastMaxWeight, specifier: "%.1f") KG")
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
                if !isInsideGroup { restBadge }
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
    }

    @ViewBuilder
    private var notesView: some View {
        if showNotes || !exercise.exerciseNotes.isEmpty || (lastSessionNotes != nil && !lastSessionNotes!.isEmpty) {
            VStack(alignment: .leading, spacing: 12) {
                if let previousNotes = lastSessionNotes,
                   !previousNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("NOTE PRECEDENTI")
                            .font(.system(size: 9, weight: .bold)).foregroundColor(.white.opacity(0.4))
                        Text(previousNotes)
                            .font(.system(size: 12)).foregroundColor(.white.opacity(0.7)).italic()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.03)))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("NOTE SESSIONE")
                        .font(.system(size: 9, weight: .bold)).foregroundColor(accentColor.opacity(0.7))
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
    }

    private var setsTableView: some View {
        VStack(spacing: 0) {
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

            ForEach(exercise.sets.indices, id: \.self) { index in
                setRowView(for: index)
            }
        }
    }

    @ViewBuilder
    private func setRowView(for index: Int) -> some View {
        let isCompleted = exercise.sets[index].isCompleted
        HStack {
            Text("\(index + 1)")
                .font(.system(size: 14, weight: .black, design: .monospaced))
                .foregroundColor(isCompleted ? accentColor.opacity(0.5) : accentColor)
                .frame(width: 30, alignment: .center)
            Spacer()
            repsTextField(for: index, isCompleted: isCompleted)
            if !exercise.isBodyweight {
                Spacer()
                weightTextField(for: index, isCompleted: isCompleted)
            }
            Spacer()
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

    @ViewBuilder
    private func repsTextField(for index: Int, isCompleted: Bool) -> some View {
        let hasGhost = cachedLastSessionData?.sets.indices.contains(index) ?? false
        let ghostVal = hasGhost ? cachedLastSessionData!.sets[index].reps : 0
        let ph = hasGhost ? "\(ghostVal)" : "0"
        TextField(ph,
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
    }

    @ViewBuilder
    private func weightTextField(for index: Int, isCompleted: Bool) -> some View {
        let hasGhost = cachedLastSessionData?.sets.indices.contains(index) ?? false
        let ghostVal = hasGhost ? cachedLastSessionData!.sets[index].weight : 0.0
        let ph = hasGhost ? "\(String(format: "%.1f", ghostVal))" : "0.0"
        TextField(ph,
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

    private var footerView: some View {
        HStack {
            Button(action: addSet) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("AGGIUNGI SET")
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(accentColor)
                .padding(.vertical, 8).padding(.horizontal, 12)
                .background(RoundedRectangle(cornerRadius: 8).fill(accentColor.opacity(0.1)))
            }
            Spacer()
            if exercise.sets.count > 1 {
                Button(action: {
                    withAnimation { _ = exercise.sets.popLast() }
                }) {
                    Text("RIMUOVI SET")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.red.opacity(0.7))
                        .padding(.vertical, 8).padding(.horizontal, 12)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.red.opacity(0.1)))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    @ViewBuilder
    private var restBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "timer").font(.system(size: 10, weight: .bold))
            Text(formatRest(restSeconds)).font(.system(size: 11, weight: .bold))
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
        exercise.sets.append(WorkoutSet(
            id: UUID().uuidString, setIndex: newIndex,
            reps: lastSet?.reps ?? 10, weight: lastSet?.weight ?? 0,
            isPR: false, isCompleted: false
        ))
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func prefillGhostWeights() {
        guard let lastData = cachedLastSessionData else { return }
        for index in exercise.sets.indices {
            if index < lastData.sets.count {
                let ghostSet = lastData.sets[index]
                if exercise.sets[index].reps == 0 { exercise.sets[index].reps = ghostSet.reps }
                if exercise.sets[index].weight == 0 && !exercise.isBodyweight {
                    exercise.sets[index].weight = ghostSet.weight
                }
            }
        }
    }
}
