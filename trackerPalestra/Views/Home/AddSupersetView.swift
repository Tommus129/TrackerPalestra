import SwiftUI

// MARK: - SupersetExState

struct SupersetExState {
    var name: String = ""
    var sets: Int = 3
    var variableReps: Bool = false
    var uniformReps: Int = 10
    var repsPerSet: [Int] = Array(repeating: 10, count: 3)

    var resolvedReps: [Int] {
        variableReps ? Array(repsPerSet.prefix(sets)) : [uniformReps]
    }

    mutating func syncRepsArray() {
        while repsPerSet.count < sets { repsPerSet.append(repsPerSet.last ?? 10) }
        while repsPerSet.count > sets { repsPerSet.removeLast() }
    }
}

struct AddSupersetView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @Environment(\.dismiss) var dismiss
    @Binding var day: WorkoutPlanDay

    @State private var isCircuit = false
    @State private var supersetName = "Superset"
    @State private var restSeconds = 60
    @State private var exStates: [SupersetExState] = [SupersetExState(), SupersetExState()]

    private let corner: CGFloat = 12
    private var accent: Color { isCircuit ? .cyan : .acidGreen }

    var canSave: Bool {
        exStates.allSatisfy { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    typeToggle
                    nameSection
                    restSection
                    exercisesSection
                    saveButton
                }
                .padding()
            }
        }
        .navigationTitle(isCircuit ? "Nuovo Circuito" : "Nuovo Superset")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Annulla") { dismiss() }
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }

    // MARK: - Sections

    /// Toggle Superset / Circuito in cima
    private var typeToggle: some View {
        VStack(alignment: .leading, spacing: 10) {
            label("TIPO")
            HStack(spacing: 0) {
                typeButton(title: "SUPERSET", icon: "link", selected: !isCircuit) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isCircuit = false
                        if supersetName == "Circuito" { supersetName = "Superset" }
                    }
                }
                typeButton(title: "CIRCUITO", icon: "arrow.3.trianglepath", selected: isCircuit) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isCircuit = true
                        if supersetName == "Superset" { supersetName = "Circuito" }
                    }
                }
            }
            .background(RoundedRectangle(cornerRadius: corner).fill(Color.white.opacity(0.05)))
            .overlay(RoundedRectangle(cornerRadius: corner).stroke(Color.white.opacity(0.08), lineWidth: 1))

            // Descrizione del tipo selezionato
            Text(isCircuit
                 ? "Il timer parte dopo che tutti gli esercizi del giro sono stati completati."
                 : "Il timer parte dopo ogni singolo giro completo degli esercizi.")
                .font(.caption)
                .foregroundColor(.white.opacity(0.4))
                .padding(.horizontal, 4)
        }
    }

    private func typeButton(title: String, icon: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 11, weight: .bold))
                Text(title).font(.system(size: 12, weight: .black)).tracking(0.5)
            }
            .foregroundColor(selected ? .black : .white.opacity(0.4))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: corner)
                    .fill(selected ? accent : Color.clear)
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selected)
        }
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            label(isCircuit ? "NOME CIRCUITO" : "NOME SUPERSET")
            TextField(isCircuit ? "Es. Circuito A" : "Es. A1/A2", text: $supersetName)
                .foregroundColor(.white).padding(14).background(fieldBg).accentColor(accent)
        }
    }

    private var restSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            label(isCircuit ? "RECUPERO DOPO OGNI GIRO" : "RECUPERO DOPO BLOCCO (secondi)")
            HStack(spacing: 16) {
                stepButton(icon: "minus") { if restSeconds >= 15 { restSeconds -= 15 } }
                Text("\(restSeconds)\"")
                    .font(.title2).fontWeight(.bold).foregroundColor(.white)
                stepButton(icon: "plus") { restSeconds += 15 }
                Spacer()
            }
            .padding(14).background(fieldBg)
            // Preset rapidi
            HStack(spacing: 8) {
                ForEach([30, 60, 90, 120, 180], id: \.self) { sec in
                    Button { restSeconds = sec } label: {
                        Text(sec < 60 ? "\(sec)s" : "\(sec/60)m")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(restSeconds == sec ? .black : accent)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(Capsule().fill(restSeconds == sec ? accent : accent.opacity(0.1)))
                    }
                }
            }
        }
    }

    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            label(isCircuit ? "ESERCIZI NEL CIRCUITO" : "ESERCIZI NEL SUPERSET")
            ForEach(exStates.indices, id: \.self) { i in
                supersetExRow(index: i)
            }
            Button {
                exStates.append(SupersetExState())
            } label: {
                Label("Aggiungi esercizio", systemImage: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: corner)
                        .strokeBorder(accent.opacity(0.5), lineWidth: 1))
            }
        }
    }

    private var saveButton: some View {
        Button(action: save) {
            Text(isCircuit ? "AGGIUNGI CIRCUITO" : "AGGIUNGI SUPERSET")
                .font(.system(size: 15, weight: .bold)).tracking(0.8)
                .foregroundColor(canSave ? .black : .gray.opacity(0.4))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: corner)
                        .fill(canSave ? accent : Color.gray.opacity(0.2))
                )
        }
        .disabled(!canSave)
        .padding(.top, 8)
    }

    // MARK: - Exercise row

    @ViewBuilder
    private func supersetExRow(index i: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {

            // Nome + autocomplete
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("\(i + 1).")
                        .font(.system(size: 13, weight: .bold)).foregroundColor(accent)
                    TextField("Nome esercizio", text: $exStates[i].name)
                        .foregroundColor(.white).accentColor(accent)
                    if exStates.count > 2 {
                        Button(role: .destructive) {
                            exStates.remove(at: i)
                        } label: {
                            Image(systemName: "trash").foregroundColor(.red.opacity(0.7))
                        }
                    }
                }
                .padding(12).background(fieldBg)

                let suggestions = suggestions(for: exStates[i].name)
                if !suggestions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(suggestions, id: \.self) { suggestion in
                                Button { exStates[i].name = suggestion } label: {
                                    Text(suggestion)
                                        .font(.subheadline).fontWeight(.medium)
                                        .foregroundColor(accent)
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(
                                            Capsule().fill(accent.opacity(0.1))
                                                .overlay(Capsule().strokeBorder(accent.opacity(0.3), lineWidth: 1))
                                        )
                                }
                            }
                        }
                    }
                }
            }

            // Serie
            HStack(spacing: 16) {
                Text("SERIE").font(.caption2).fontWeight(.bold).foregroundColor(.gray)
                stepButton(icon: "minus") {
                    if exStates[i].sets > 1 { exStates[i].sets -= 1; exStates[i].syncRepsArray() }
                }
                Text("\(exStates[i].sets)")
                    .font(.system(size: 16, weight: .bold)).foregroundColor(.white).frame(minWidth: 30)
                stepButton(icon: "plus") {
                    if exStates[i].sets < 10 { exStates[i].sets += 1; exStates[i].syncRepsArray() }
                }
                Spacer()
            }
            .padding(10).background(fieldBg)

            // Ripetizioni
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("RIPETIZIONI").font(.caption2).fontWeight(.bold).foregroundColor(.gray)
                    Spacer()
                    Toggle("", isOn: $exStates[i].variableReps).labelsHidden().tint(accent)
                        .onChange(of: exStates[i].variableReps) { on in
                            if on { exStates[i].repsPerSet = Array(repeating: exStates[i].uniformReps, count: exStates[i].sets) }
                        }
                    Text("Diverse per serie").font(.caption2).foregroundColor(.gray)
                }
                if exStates[i].variableReps {
                    VStack(spacing: 6) {
                        ForEach(exStates[i].repsPerSet.indices, id: \.self) { s in
                            HStack {
                                Text("Serie \(s + 1)")
                                    .font(.system(size: 12)).foregroundColor(.gray)
                                    .frame(width: 56, alignment: .leading)
                                Spacer()
                                stepButton(icon: "minus") {
                                    if exStates[i].repsPerSet[s] > 1 { exStates[i].repsPerSet[s] -= 1 }
                                }
                                Text("\(exStates[i].repsPerSet[s])")
                                    .font(.system(size: 15, weight: .bold)).foregroundColor(accent).frame(minWidth: 30)
                                stepButton(icon: "plus") {
                                    exStates[i].repsPerSet[s] += 1
                                }
                            }
                        }
                    }
                } else {
                    HStack(spacing: 14) {
                        stepButton(icon: "minus") {
                            if exStates[i].uniformReps > 1 { exStates[i].uniformReps -= 1 }
                        }
                        Text("\(exStates[i].uniformReps)")
                            .font(.system(size: 16, weight: .bold)).foregroundColor(.white).frame(minWidth: 30)
                        stepButton(icon: "plus") { exStates[i].uniformReps += 1 }
                        Spacer()
                    }
                }
            }
            .padding(10).background(fieldBg)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: corner)
                .fill(accent.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: corner).stroke(accent.opacity(0.15), lineWidth: 1))
        )
    }

    // MARK: - Helpers

    private func suggestions(for text: String) -> [String] {
        guard !text.isEmpty else { return [] }
        return viewModel.exerciseNames.filter {
            $0.lowercased().contains(text.lowercased()) && $0.lowercased() != text.lowercased()
        }
    }

    private func label(_ text: String) -> some View {
        Text(text).font(.caption).fontWeight(.bold).foregroundColor(accent).tracking(1)
    }

    private var fieldBg: some View {
        RoundedRectangle(cornerRadius: corner)
            .fill(Color(UIColor.systemGray6).opacity(0.14))
            .overlay(RoundedRectangle(cornerRadius: corner).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private func stepButton(icon: String, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold)).foregroundColor(accent)
                .frame(width: 32, height: 32).background(Circle().fill(accent.opacity(0.15)))
        }
    }

    private func save() {
        let exercises = exStates.map { s in
            WorkoutPlanExercise(
                name: s.name.trimmingCharacters(in: .whitespaces),
                sets: s.sets,
                repsBySet: s.resolvedReps,
                isBodyweight: false
            )
        }
        let ss = WorkoutPlanSuperset(
            name: supersetName,
            exercises: exercises,
            restAfterSeconds: restSeconds,
            isCircuit: isCircuit
        )
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            day.items.append(WorkoutPlanItem(kind: .superset, superset: ss))
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}
