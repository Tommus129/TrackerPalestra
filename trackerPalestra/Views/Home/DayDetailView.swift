import SwiftUI

// MARK: - DayDetailView

struct DayDetailView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @Binding var day: WorkoutPlanDay

    @State private var showAddSheet = false
    @State private var addingSuperset = false

    private let corner: CGFloat = 12

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            List {
                // Nome giorno
                Section {
                    TextField("Nome giorno", text: $day.label)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.vertical, 4)
                        .accentColor(.acidGreen)
                } header: { sectionHeader(icon: "calendar", title: "NOME GIORNO") }
                .listRowBackground(rowBg)
                .listRowSeparator(.hidden)

                // Lista items
                Section {
                    ForEach(day.items.indices, id: \.self) { idx in
                        itemRow(idx: idx)
                    }
                    .onDelete { offsets in
                        withAnimation { day.items.remove(atOffsets: offsets) }
                    }
                    .onMove { from, to in
                        day.items.move(fromOffsets: from, toOffset: to)
                    }
                } header: { sectionHeader(icon: "list.bullet", title: "ESERCIZI") }
                .listRowBackground(rowBg)
                .listRowSeparator(.hidden)

                // Bottoni aggiungi
                Section {
                    addButtons
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .scrollContentBackground(.hidden)
            .environment(\.editMode, .constant(.active))
        }
        .navigationTitle(day.label)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showAddSheet) {
            if addingSuperset {
                AddSupersetSheet(day: $day)
            } else {
                AddExerciseSheet(day: $day, viewModel: viewModel)
            }
        }
        .onAppear { migrateLegacyIfNeeded() }
    }

    // MARK: - Item rows

    @ViewBuilder
    private func itemRow(idx: Int) -> some View {
        let item = day.items[idx]
        switch item.kind {
        case .exercise:
            if let ex = item.exercise {
                ExerciseItemRow(exercise: ex) {
                    withAnimation { day.items.remove(at: idx) }
                }
            }
        case .superset:
            if let ss = item.superset {
                SupersetItemRow(superset: ss) {
                    withAnimation { day.items.remove(at: idx) }
                }
            }
        }
    }

    // MARK: - Add buttons

    private var addButtons: some View {
        VStack(spacing: 10) {
            Button {
                addingSuperset = false
                showAddSheet = true
            } label: {
                Label("AGGIUNGI ESERCIZIO", systemImage: "plus")
                    .font(.system(size: 15, weight: .bold))
                    .tracking(0.8)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: corner).fill(Color.acidGreen))
            }

            Button {
                addingSuperset = true
                showAddSheet = true
            } label: {
                Label("AGGIUNGI SUPERSET", systemImage: "link")
                    .font(.system(size: 15, weight: .bold))
                    .tracking(0.8)
                    .foregroundColor(.acidGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: corner)
                            .strokeBorder(Color.acidGreen, lineWidth: 1.5)
                    )
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Helpers

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(.acidGreen)
            Text(title)
        }
        .font(.caption).fontWeight(.bold).foregroundColor(.gray)
    }

    private var rowBg: some View {
        RoundedRectangle(cornerRadius: corner)
            .fill(Color(UIColor.systemGray6).opacity(0.12))
            .overlay(RoundedRectangle(cornerRadius: corner).stroke(Color.white.opacity(0.05), lineWidth: 1))
    }

    private func migrateLegacyIfNeeded() {
        guard day.items.isEmpty, let legacy = day.exercises, !legacy.isEmpty else { return }
        day.items = legacy.map { WorkoutPlanItem(kind: .exercise, exercise: $0) }
    }
}

// MARK: - ExerciseItemRow

struct ExerciseItemRow: View {
    let exercise: WorkoutPlanExercise
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.acidGreen.opacity(0.1)).frame(width: 44, height: 44)
                Image(systemName: exercise.isBodyweight ? "figure.flexibility" : "dumbbell.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.acidGreen)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                HStack(spacing: 6) {
                    Text("\(exercise.sets) ×")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                    Text(exercise.repsDisplay)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.acidGreen)
                    if exercise.isBodyweight {
                        Text("BW")
                            .font(.caption2).fontWeight(.black)
                            .foregroundColor(.black)
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(Capsule().fill(Color.acidGreen))
                    }
                }

                if !exercise.notes.isEmpty {
                    Text(exercise.notes).font(.caption).foregroundColor(.gray).lineLimit(1)
                }
            }
            Spacer()

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.red.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.red.opacity(0.1)))
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - SupersetItemRow

struct SupersetItemRow: View {
    let superset: WorkoutPlanSuperset
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(superset.name, systemImage: "link")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.orange)
                Spacer()
                Text("Rec. \(superset.restAfterSeconds)\"")
                    .font(.caption).foregroundColor(.gray)
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.red.opacity(0.7))
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.red.opacity(0.1)))
                }
            }

            ForEach(superset.exercises.indices, id: \.self) { i in
                let ex = superset.exercises[i]
                HStack(spacing: 10) {
                    Text("\(i + 1).")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.orange.opacity(0.7))
                        .frame(width: 18)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ex.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Text("\(ex.sets) × \(ex.repsDisplay)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.acidGreen)
                    }
                    Spacer()
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.2), lineWidth: 1))
        )
        .padding(.vertical, 4)
    }
}

// MARK: - AddExerciseSheet

struct AddExerciseSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var day: WorkoutPlanDay
    var viewModel: MainViewModel

    @State private var name = ""
    @State private var notes = ""
    @State private var sets = 3
    @State private var variableReps = false
    @State private var uniformReps = 8
    @State private var repsPerSet: [Int] = Array(repeating: 8, count: 3)
    @State private var isBodyweight = false

    private let corner: CGFloat = 12

    var suggestions: [String] {
        guard !name.isEmpty else { return [] }
        return viewModel.exerciseNames.filter {
            $0.lowercased().contains(name.lowercased()) && $0.lowercased() != name.lowercased()
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        nameSection
                        setsSection
                        repsSection
                        bodyweightToggle
                        notesSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Nuovo Esercizio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }.foregroundColor(.white.opacity(0.6))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Aggiungi") { save() }
                        .fontWeight(.bold)
                        .foregroundColor(name.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : .acidGreen)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    // MARK: Sections

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("NOME ESERCIZIO")
            TextField("Es. Hack Squat", text: $name)
                .foregroundColor(.white)
                .padding(14)
                .background(fieldBg)
                .accentColor(.acidGreen)
            if !suggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(suggestions, id: \.self) { s in
                            Button { name = s } label: {
                                Text(s)
                                    .font(.subheadline).fontWeight(.medium)
                                    .foregroundColor(.acidGreen)
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(Capsule().fill(Color.acidGreen.opacity(0.1))
                                        .overlay(Capsule().strokeBorder(Color.acidGreen.opacity(0.3), lineWidth: 1)))
                            }
                        }
                    }
                }
            }
        }
    }

    private var setsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("SERIE")
            HStack(spacing: 16) {
                stepButton(systemName: "minus") {
                    if sets > 1 {
                        sets -= 1
                        if variableReps && repsPerSet.count > 1 {
                            repsPerSet.removeLast()
                        }
                    }
                }
                Text("\(sets)")
                    .font(.title2).fontWeight(.bold).foregroundColor(.white).frame(minWidth: 40)
                stepButton(systemName: "plus") {
                    if sets < 10 {
                        sets += 1
                        if variableReps {
                            repsPerSet.append(repsPerSet.last ?? 8)
                        }
                    }
                }
                Spacer()
            }
            .padding(14)
            .background(fieldBg)
        }
    }

    private var repsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                label("RIPETIZIONI")
                Spacer()
                Toggle("", isOn: $variableReps)
                    .labelsHidden()
                    .tint(.acidGreen)
                Text("Diverse per serie")
                    .font(.caption).foregroundColor(.gray)
            }

            if variableReps {
                // Un campo per ogni serie
                VStack(spacing: 8) {
                    ForEach(0..<sets, id: \.self) { i in
                        HStack {
                            Text("Serie \(i + 1)")
                                .font(.system(size: 13)).foregroundColor(.gray)
                                .frame(width: 60, alignment: .leading)
                            Spacer()
                            stepButton(systemName: "minus") {
                                if i < repsPerSet.count, repsPerSet[i] > 1 { repsPerSet[i] -= 1 }
                            }
                            Text("\(i < repsPerSet.count ? repsPerSet[i] : 8)")
                                .font(.system(size: 17, weight: .bold)).foregroundColor(.acidGreen)
                                .frame(minWidth: 34)
                            stepButton(systemName: "plus") {
                                if i < repsPerSet.count { repsPerSet[i] += 1 }
                            }
                        }
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(fieldBg)
                    }
                }
                .onChange(of: variableReps) { on in
                    if on {
                        repsPerSet = Array(repeating: uniformReps, count: sets)
                    }
                }
            } else {
                HStack(spacing: 16) {
                    stepButton(systemName: "minus") { if uniformReps > 1 { uniformReps -= 1 } }
                    Text("\(uniformReps)")
                        .font(.title2).fontWeight(.bold).foregroundColor(.white).frame(minWidth: 40)
                    stepButton(systemName: "plus") { uniformReps += 1 }
                    Spacer()
                }
                .padding(14)
                .background(fieldBg)
            }
        }
    }

    private var bodyweightToggle: some View {
        Button { isBodyweight.toggle() } label: {
            HStack {
                Image(systemName: isBodyweight ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isBodyweight ? .acidGreen : .white.opacity(0.3))
                Text("Corpo libero")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: corner)
                    .fill(isBodyweight ? Color.acidGreen.opacity(0.1) : Color.white.opacity(0.05))
                    .overlay(RoundedRectangle(cornerRadius: corner)
                        .stroke(isBodyweight ? Color.acidGreen.opacity(0.3) : Color.clear, lineWidth: 1))
            )
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("NOTE")
            TextField("Es. recupero 2', cadenza lenta…", text: $notes, axis: .vertical)
                .foregroundColor(.white)
                .padding(14)
                .background(fieldBg)
                .lineLimit(2...4)
                .accentColor(.acidGreen)
        }
    }

    // MARK: Helpers

    private func label(_ text: String) -> some View {
        Text(text).font(.caption).fontWeight(.bold).foregroundColor(.acidGreen).tracking(1)
    }

    private var fieldBg: some View {
        RoundedRectangle(cornerRadius: corner)
            .fill(Color(UIColor.systemGray6).opacity(0.14))
            .overlay(RoundedRectangle(cornerRadius: corner).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private func stepButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.acidGreen)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.acidGreen.opacity(0.15)))
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let finalReps: [Int]
        if variableReps {
            finalReps = repsPerSet.prefix(sets).map { $0 }
        } else {
            finalReps = [uniformReps]
        }

        let ex = WorkoutPlanExercise(
            name: viewModel.normalizeName(trimmed),
            sets: sets,
            repsBySet: finalReps,
            isBodyweight: isBodyweight,
            notes: notes
        )
        let item = WorkoutPlanItem(kind: .exercise, exercise: ex)

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            day.items.append(item)
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}

// MARK: - AddSupersetSheet

struct AddSupersetSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var day: WorkoutPlanDay

    @State private var supersetName = "Superset"
    @State private var restSeconds = 60
    @State private var exercises: [WorkoutPlanExercise] = [
        WorkoutPlanExercise(name: "", sets: 3, repsBySet: [10], isBodyweight: false),
        WorkoutPlanExercise(name: "", sets: 3, repsBySet: [10], isBodyweight: false)
    ]

    private let corner: CGFloat = 12

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Nome superset
                        VStack(alignment: .leading, spacing: 8) {
                            label("NOME SUPERSET")
                            TextField("Es. A1/A2", text: $supersetName)
                                .foregroundColor(.white)
                                .padding(14)
                                .background(fieldBg)
                                .accentColor(.acidGreen)
                        }

                        // Recupero
                        VStack(alignment: .leading, spacing: 8) {
                            label("RECUPERO DOPO BLOCCO (secondi)")
                            HStack(spacing: 16) {
                                stepButton(systemName: "minus") { if restSeconds >= 15 { restSeconds -= 15 } }
                                Text("\(restSeconds)\"")
                                    .font(.title2).fontWeight(.bold).foregroundColor(.white)
                                stepButton(systemName: "plus") { restSeconds += 15 }
                                Spacer()
                            }
                            .padding(14)
                            .background(fieldBg)
                        }

                        // Esercizi superset
                        VStack(alignment: .leading, spacing: 12) {
                            label("ESERCIZI NEL SUPERSET")
                            ForEach(exercises.indices, id: \.self) { i in
                                supersetExRow(index: i)
                            }

                            Button {
                                exercises.append(WorkoutPlanExercise(name: "", sets: 3, repsBySet: [10], isBodyweight: false))
                            } label: {
                                Label("Aggiungi esercizio", systemImage: "plus")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.orange)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(RoundedRectangle(cornerRadius: corner)
                                        .strokeBorder(Color.orange.opacity(0.5), lineWidth: 1))
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Nuovo Superset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }.foregroundColor(.white.opacity(0.6))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Aggiungi") { save() }
                        .fontWeight(.bold)
                        .foregroundColor(canSave ? .acidGreen : .gray)
                        .disabled(!canSave)
                }
            }
        }
    }

    private var canSave: Bool {
        exercises.allSatisfy { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    @ViewBuilder
    private func supersetExRow(index i: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(i + 1).")
                    .font(.system(size: 13, weight: .bold)).foregroundColor(.orange)
                TextField("Nome esercizio", text: $exercises[i].name)
                    .foregroundColor(.white)
                    .accentColor(.acidGreen)
                if exercises.count > 2 {
                    Button(role: .destructive) { exercises.remove(at: i) } label: {
                        Image(systemName: "trash").foregroundColor(.red.opacity(0.7))
                    }
                }
            }
            .padding(12)
            .background(fieldBg)

            HStack(spacing: 12) {
                // Serie
                VStack(alignment: .leading, spacing: 4) {
                    Text("SERIE").font(.caption2).fontWeight(.bold).foregroundColor(.gray)
                    HStack {
                        stepButton(systemName: "minus") { if exercises[i].sets > 1 { exercises[i].sets -= 1 } }
                        Text("\(exercises[i].sets)")
                            .font(.system(size: 16, weight: .bold)).foregroundColor(.white).frame(minWidth: 30)
                        stepButton(systemName: "plus") { if exercises[i].sets < 10 { exercises[i].sets += 1 } }
                    }
                }
                .padding(10)
                .background(fieldBg)
                .frame(maxWidth: .infinity)

                // Reps
                VStack(alignment: .leading, spacing: 4) {
                    Text("REPS").font(.caption2).fontWeight(.bold).foregroundColor(.gray)
                    HStack {
                        stepButton(systemName: "minus") {
                            if let r = exercises[i].repsBySet.first, r > 1 { exercises[i].repsBySet[0] = r - 1 }
                        }
                        Text("\(exercises[i].repsBySet.first ?? 10)")
                            .font(.system(size: 16, weight: .bold)).foregroundColor(.acidGreen).frame(minWidth: 30)
                        stepButton(systemName: "plus") {
                            exercises[i].repsBySet[0] = (exercises[i].repsBySet.first ?? 10) + 1
                        }
                    }
                }
                .padding(10)
                .background(fieldBg)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: corner)
                .fill(Color.orange.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: corner).stroke(Color.orange.opacity(0.15), lineWidth: 1))
        )
    }

    private func label(_ text: String) -> some View {
        Text(text).font(.caption).fontWeight(.bold).foregroundColor(.orange).tracking(1)
    }

    private var fieldBg: some View {
        RoundedRectangle(cornerRadius: corner)
            .fill(Color(UIColor.systemGray6).opacity(0.14))
            .overlay(RoundedRectangle(cornerRadius: corner).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private func stepButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.orange)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.orange.opacity(0.15)))
        }
    }

    private func save() {
        let ss = WorkoutPlanSuperset(
            name: supersetName,
            exercises: exercises,
            restAfterSeconds: restSeconds
        )
        let item = WorkoutPlanItem(kind: .superset, superset: ss)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            day.items.append(item)
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}
