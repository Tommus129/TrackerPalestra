import SwiftUI

struct DayEditorView: View {
    @Binding var day: WorkoutPlanDay
    var onDelete: () -> Void

    @State private var newExerciseName: String = ""
    @State private var newIsBodyweight: Bool = false
    @State private var newNotes: String = ""

    // Modalità 2: reps per set (sempre)
    @State private var newSetsCount: Int = 4
    @State private var newBaseReps: Int = 10
    @State private var newRepScheme: [Int] = [10, 9, 9, 8]

    @State private var newRestSeconds: Int = 120

    // Super serie
    @State private var newIsSuperSetWithPrevious: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            header

            if day.exercises.isEmpty {
                emptyState
            } else {
                exercisesList
            }

            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.vertical, 8)

            newExerciseSection
        }
        .padding(.vertical, 8)
        .onAppear {
            normalizeScheme()
        }
        .onChange(of: newSetsCount) { _, _ in
            resizeSchemeToSetsCount()
        }
        .onChange(of: newBaseReps) { _, _ in
            // Non forziamo automaticamente tutte uguali (perché vogliamo la Modalità 2),
            // ma diamo un modo rapido: bottone "Uniforma"
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            TextField("Nome Giorno", text: $day.label)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                )

            Button(role: .destructive) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onDelete()
            } label: {
                Image(systemName: "trash.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.red.opacity(0.8))
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.1))
                    )
            }
        }
    }

    // MARK: - Empty

    private var emptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "figure.run")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.2))
                Text("Nessun esercizio")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.vertical, 30)
            Spacer()
        }
    }

    // MARK: - Exercises list (con raggruppamento SS)

    private var exercisesList: some View {
        VStack(spacing: 10) {
            ForEach(groupedExercises(), id: \.id) { group in
                if group.exercises.count >= 2 {
                    superSetGroupView(group)
                } else if let single = group.exercises.first,
                          let idx = day.exercises.firstIndex(where: { $0.id == single.id }) {
                    exerciseRow(exercise: $day.exercises[idx])
                }
            }
        }
    }

    private struct ExerciseGroup: Identifiable {
        var id: String
        var exercises: [WorkoutPlanExercise]
        var isSuperSet: Bool
    }

    private func groupedExercises() -> [ExerciseGroup] {
        // Mantiene l’ordine originale.
        var result: [ExerciseGroup] = []
        var i = 0
        while i < day.exercises.count {
            let ex = day.exercises[i]
            if let gid = ex.superSetGroupID {
                // Prendi tutti consecutivi con stesso gid
                var j = i
                var bucket: [WorkoutPlanExercise] = []
                while j < day.exercises.count, day.exercises[j].superSetGroupID == gid {
                    bucket.append(day.exercises[j])
                    j += 1
                }
                result.append(ExerciseGroup(id: gid, exercises: bucket, isSuperSet: true))
                i = j
            } else {
                result.append(ExerciseGroup(id: ex.id, exercises: [ex], isSuperSet: false))
                i += 1
            }
        }
        return result
    }

    private func superSetGroupView(_ group: ExerciseGroup) -> some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.acidGreen)
                .frame(width: 3)
                .padding(.vertical, 6)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("SUPER SERIE")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.acidGreen)
                        .tracking(2)
                    Spacer()

                    Button {
                        // Rimuove super serie dal gruppo
                        removeSuperSet(groupID: group.id)
                    } label: {
                        Text("Scollega")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 12)

                ForEach(group.exercises) { item in
                    if let idx = day.exercises.firstIndex(where: { $0.id == item.id }) {
                        exerciseRow(exercise: $day.exercises[idx])
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.acidGreen.opacity(0.18), lineWidth: 1)
                )
        )
    }

    // MARK: - Single row

    private func exerciseRow(exercise: Binding<WorkoutPlanExercise>) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                TextField("Nome esercizio", text: exercise.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                HStack(spacing: 10) {
                    // Reps scheme summary
                    Text(repSummary(exercise.wrappedValue.effectiveRepScheme))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.acidGreen)

                    Text("·")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.25))

                    Text("Rec. \(restSummary(exercise.wrappedValue.restSeconds))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))

                    if exercise.wrappedValue.isBodyweight {
                        Text("BW")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.acidGreen))
                    }
                }
            }

            Spacer()

            Button(role: .destructive) {
                deleteExercise(exercise.wrappedValue)
            } label: {
                Image(systemName: "trash.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.red.opacity(0.7))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.red.opacity(0.1)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.deepPurple.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - New exercise section (Modalità 2)

    private var newExerciseSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("NUOVO ESERCIZIO")
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.acidGreen)
                .tracking(2)

            TextField("Nome esercizio", text: $newExerciseName)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.deepPurple.opacity(0.3), lineWidth: 1)
                        )
                )

            // Serie + “uniforma”
            VStack(alignment: .leading, spacing: 12) {
                Text("SERIE E RIPETIZIONI")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(1)

                HStack(spacing: 12) {
                    compactStepper(title: "SERIE", value: $newSetsCount, min: 1, max: 10)

                    compactStepper(title: "BASE", value: $newBaseReps, min: 1, max: 30)

                    Button {
                        uniformScheme(to: newBaseReps)
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    } label: {
                        Text("Uniforma")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.acidGreen))
                    }
                }

                // Lista set (Modalità 2)
                VStack(spacing: 8) {
                    ForEach(newRepScheme.indices, id: \.self) { idx in
                        HStack(spacing: 10) {
                            Text("Set \(idx + 1)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 52, alignment: .leading)

                            HStack(spacing: 10) {
                                Button {
                                    if newRepScheme[idx] > 1 {
                                        newRepScheme[idx] -= 1
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.acidGreen)
                                }

                                Text("\(newRepScheme[idx])")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(minWidth: 44)
                                    .monospacedDigit()

                                Button {
                                    if newRepScheme[idx] < 30 {
                                        newRepScheme[idx] += 1
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.acidGreen)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.04))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.deepPurple.opacity(0.25), lineWidth: 1)
                                    )
                            )

                            Spacer()

                            Button {
                                guard newRepScheme.count > 1 else { return }
                                newRepScheme.remove(at: idx)
                                newSetsCount = newRepScheme.count
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 14))
                                    .foregroundColor(.red.opacity(0.7))
                                    .frame(width: 36, height: 36)
                                    .background(Circle().fill(Color.red.opacity(0.1)))
                            }
                            .disabled(newRepScheme.count <= 1)
                            .opacity(newRepScheme.count <= 1 ? 0.35 : 1)
                        }
                    }

                    Button {
                        let last = newRepScheme.last ?? newBaseReps
                        newRepScheme.append(max(1, last - 1)) // smart default decrescente
                        newSetsCount = newRepScheme.count
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                            Text("Aggiungi set")
                                .font(.system(size: 13, weight: .black))
                                .tracking(1)
                        }
                        .foregroundColor(.acidGreen)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.02))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.acidGreen.opacity(0.15), lineWidth: 1)
                                )
                        )
                    }
                    .padding(.top, 4)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.03))
            )

            // Recupero quick pills
            VStack(alignment: .leading, spacing: 10) {
                Text("RECUPERO")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(1)

                HStack(spacing: 10) {
                    restPill(seconds: 60)
                    restPill(seconds: 90)
                    restPill(seconds: 120)
                    restPill(seconds: 150)
                }
            }

            // Super serie con precedente
            Button {
                newIsSuperSetWithPrevious.toggle()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                HStack {
                    Image(systemName: newIsSuperSetWithPrevious ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(newIsSuperSetWithPrevious ? .acidGreen : .white.opacity(0.3))

                    Text("Super serie con esercizio precedente")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))

                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(newIsSuperSetWithPrevious ? Color.acidGreen.opacity(0.08) : Color.white.opacity(0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(newIsSuperSetWithPrevious ? Color.acidGreen.opacity(0.25) : Color.clear, lineWidth: 1)
                        )
                )
            }
            .disabled(day.exercises.isEmpty)
            .opacity(day.exercises.isEmpty ? 0.35 : 1)

            // Bodyweight
            Button {
                newIsBodyweight.toggle()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                HStack {
                    Image(systemName: newIsBodyweight ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(newIsBodyweight ? .acidGreen : .white.opacity(0.3))

                    Text("Esercizio a corpo libero")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))

                    Spacer()

                    if newIsBodyweight {
                        Text("BW")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.acidGreen))
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(newIsBodyweight ? Color.acidGreen.opacity(0.1) : Color.white.opacity(0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(newIsBodyweight ? Color.acidGreen.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                )
            }

            // Note
            TextField("Note (opzionale)", text: $newNotes)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.deepPurple.opacity(0.2), lineWidth: 1)
                        )
                )

            // Add
            Button {
                addExercise()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("AGGIUNGI ESERCIZIO")
                        .font(.system(size: 13, weight: .black))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(canAdd ? Color.acidGreen : Color.gray.opacity(0.2))
                        .shadow(color: canAdd ? Color.acidGreen.opacity(0.25) : .clear, radius: 10, y: 4)
                )
                .foregroundColor(canAdd ? .black : .white.opacity(0.3))
            }
            .disabled(!canAdd)
        }
    }

    private var canAdd: Bool {
        !newExerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Small UI components

    private func compactStepper(title: String, value: Binding<Int>, min: Int, max: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white.opacity(0.5))
                .tracking(1)

            HStack(spacing: 10) {
                Button {
                    if value.wrappedValue > min {
                        value.wrappedValue -= 1
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.acidGreen)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.deepPurple.opacity(0.5)))
                }

                Text("\(value.wrappedValue)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(minWidth: 34)
                    .monospacedDigit()

                Button {
                    if value.wrappedValue < max {
                        value.wrappedValue += 1
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.acidGreen)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.deepPurple.opacity(0.5)))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func restPill(seconds: Int) -> some View {
        Button {
            newRestSeconds = seconds
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Text(restSummary(seconds))
                .font(.system(size: 12, weight: .black))
                .foregroundColor(newRestSeconds == seconds ? .black : .white.opacity(0.65))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(newRestSeconds == seconds ? Color.acidGreen : Color.white.opacity(0.05))
                )
        }
    }

    // MARK: - Actions

    private func addExercise() {
        let trimmed = newExerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        normalizeScheme()

        var groupID: String? = nil
        if newIsSuperSetWithPrevious, let last = day.exercises.last {
            if let existing = last.superSetGroupID {
                groupID = existing
            } else {
                let newGroup = UUID().uuidString
                if let lastIdx = day.exercises.indices.last {
                    day.exercises[lastIdx].superSetGroupID = newGroup
                }
                groupID = newGroup
            }
        }

        // Retrocompatibilità: defaultSets/defaultReps continuano ad esistere,
        // ma noi salviamo anche repScheme.
        let ex = WorkoutPlanExercise(
            id: UUID().uuidString,
            name: trimmed,
            defaultSets: max(1, newRepScheme.count),
            defaultReps: newRepScheme.first ?? newBaseReps,
            isBodyweight: newIsBodyweight,
            notes: newNotes,
            repScheme: newRepScheme,
            restSeconds: newRestSeconds,
            superSetGroupID: groupID
        )

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            day.exercises.append(ex)
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        // Reset “smart” per inserimento rapido
        newExerciseName = ""
        newNotes = ""
        newIsBodyweight = false
        newIsSuperSetWithPrevious = false
        newRestSeconds = 120

        // Manteniamo schema di default utile (4 set in decrescita)
        newSetsCount = 4
        newBaseReps = 10
        newRepScheme = [10, 9, 9, 8]
    }

    private func deleteExercise(_ exercise: WorkoutPlanExercise) {
        if let idx = day.exercises.firstIndex(where: { $0.id == exercise.id }) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                day.exercises.remove(at: idx)
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    private func removeSuperSet(groupID: String) {
        for i in day.exercises.indices {
            if day.exercises[i].superSetGroupID == groupID {
                day.exercises[i].superSetGroupID = nil
            }
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    // MARK: - Scheme helpers

    private func normalizeScheme() {
        if newRepScheme.isEmpty {
            newRepScheme = Array(repeating: newBaseReps, count: max(1, newSetsCount))
        }
        newSetsCount = max(1, newRepScheme.count)
    }

    private func resizeSchemeToSetsCount() {
        newSetsCount = max(1, min(10, newSetsCount))

        if newRepScheme.count == newSetsCount { return }

        if newRepScheme.count < newSetsCount {
            while newRepScheme.count < newSetsCount {
                let last = newRepScheme.last ?? newBaseReps
                newRepScheme.append(max(1, last - 1))
            }
        } else {
            newRepScheme = Array(newRepScheme.prefix(newSetsCount))
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func uniformScheme(to reps: Int) {
        newBaseReps = reps
        newRepScheme = Array(repeating: reps, count: max(1, newSetsCount))
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    // MARK: - Formatting

    private func repSummary(_ scheme: [Int]) -> String {
        scheme.map { "\($0)" }.joined(separator: " · ")
    }

    private func restSummary(_ seconds: Int) -> String {
        if seconds <= 0 { return "0\"" }
        let m = seconds / 60
        let s = seconds % 60
        if s == 0 { return "\(m)'" }
        return "\(m)'\(s)\""
    }
}
