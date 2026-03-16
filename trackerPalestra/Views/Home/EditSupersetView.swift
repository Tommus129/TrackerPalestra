import SwiftUI

/// Modifica un superset già esistente in un giorno.
struct EditSupersetView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @Environment(\.dismiss) var dismiss
    @Binding var item: WorkoutPlanItem

    @State private var supersetName: String
    @State private var restSeconds: Int
    @State private var exStates: [SupersetExState]

    private let corner: CGFloat = 12

    init(item: Binding<WorkoutPlanItem>) {
        _item = item
        let ss = item.wrappedValue.superset ?? WorkoutPlanSuperset()
        _supersetName = State(initialValue: ss.name)
        _restSeconds  = State(initialValue: ss.restAfterSeconds)
        _exStates = State(initialValue: ss.exercises.map { ex in
            var s = SupersetExState()
            s.name = ex.name
            s.sets = ex.sets
            let isVariable = ex.repsBySet.count > 1
            s.variableReps = isVariable
            s.uniformReps  = ex.repsBySet.first ?? 10
            s.repsPerSet   = isVariable ? ex.repsBySet : Array(repeating: ex.repsBySet.first ?? 10, count: ex.sets)
            return s
        })
    }

    var canSave: Bool {
        exStates.allSatisfy { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    nameSection
                    restSection
                    exercisesSection
                    saveButton
                }
                .padding()
            }
        }
        .navigationTitle("Modifica Superset")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Annulla") { dismiss() }.foregroundColor(.white.opacity(0.6))
            }
        }
    }

    // MARK: - Sections

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("NOME SUPERSET")
            TextField("Es. A1/A2", text: $supersetName)
                .foregroundColor(.white).padding(14).background(fieldBg).accentColor(.acidGreen)
        }
    }

    private var restSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("RECUPERO DOPO BLOCCO (secondi)")
            HStack(spacing: 16) {
                stepButton(icon: "minus") { if restSeconds >= 15 { restSeconds -= 15 } }
                Text("\(restSeconds)\"")
                    .font(.title2).fontWeight(.bold).foregroundColor(.white)
                stepButton(icon: "plus") { restSeconds += 15 }
                Spacer()
            }.padding(14).background(fieldBg)
        }
    }

    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            label("ESERCIZI NEL SUPERSET")
            ForEach(exStates.indices, id: \.self) { i in
                supersetExRow(index: i)
            }
            Button { exStates.append(SupersetExState()) } label: {
                Label("Aggiungi esercizio", systemImage: "plus")
                    .font(.system(size: 14, weight: .semibold)).foregroundColor(.acidGreen)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: corner).strokeBorder(Color.acidGreen.opacity(0.5), lineWidth: 1))
            }
        }
    }

    private var saveButton: some View {
        Button(action: save) {
            Text("SALVA MODIFICHE")
                .font(.system(size: 15, weight: .bold)).tracking(0.8)
                .foregroundColor(canSave ? .black : .gray.opacity(0.4))
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: corner)
                    .fill(canSave ? Color.acidGreen : Color.gray.opacity(0.2)))
        }
        .disabled(!canSave)
        .padding(.top, 8)
    }

    @ViewBuilder
    private func supersetExRow(index i: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("\(i + 1).").font(.system(size: 13, weight: .bold)).foregroundColor(.acidGreen)
                    TextField("Nome esercizio", text: $exStates[i].name)
                        .foregroundColor(.white).accentColor(.acidGreen)
                    if exStates.count > 2 {
                        Button(role: .destructive) { exStates.remove(at: i) } label: {
                            Image(systemName: "trash").foregroundColor(.red.opacity(0.7))
                        }
                    }
                }.padding(12).background(fieldBg)

                let suggestions = viewModel.exerciseNames.filter {
                    !exStates[i].name.isEmpty &&
                    $0.lowercased().contains(exStates[i].name.lowercased()) &&
                    $0.lowercased() != exStates[i].name.lowercased()
                }
                if !suggestions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(suggestions, id: \.self) { s in
                                Button { exStates[i].name = s } label: {
                                    Text(s).font(.subheadline).fontWeight(.medium).foregroundColor(.acidGreen)
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(Capsule().fill(Color.acidGreen.opacity(0.1))
                                            .overlay(Capsule().strokeBorder(Color.acidGreen.opacity(0.3), lineWidth: 1)))
                                }
                            }
                        }
                    }
                }
            }

            HStack(spacing: 16) {
                Text("SERIE").font(.caption2).fontWeight(.bold).foregroundColor(.gray)
                stepButton(icon: "minus") {
                    if exStates[i].sets > 1 { exStates[i].sets -= 1; exStates[i].syncRepsArray() }
                }
                Text("\(exStates[i].sets)").font(.system(size: 16, weight: .bold)).foregroundColor(.white).frame(minWidth: 30)
                stepButton(icon: "plus") {
                    if exStates[i].sets < 10 { exStates[i].sets += 1; exStates[i].syncRepsArray() }
                }
                Spacer()
            }.padding(10).background(fieldBg)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("RIPETIZIONI").font(.caption2).fontWeight(.bold).foregroundColor(.gray)
                    Spacer()
                    Toggle("", isOn: $exStates[i].variableReps).labelsHidden().tint(.acidGreen)
                        .onChange(of: exStates[i].variableReps) { _, on in
                            if on { exStates[i].repsPerSet = Array(repeating: exStates[i].uniformReps, count: exStates[i].sets) }
                        }
                    Text("Diverse per serie").font(.caption2).foregroundColor(.gray)
                }
                if exStates[i].variableReps {
                    VStack(spacing: 6) {
                        ForEach(0..<exStates[i].sets, id: \.self) { s in
                            HStack {
                                Text("Serie \(s + 1)").font(.system(size: 12)).foregroundColor(.gray).frame(width: 56, alignment: .leading)
                                Spacer()
                                stepButton(icon: "minus") {
                                    if s < exStates[i].repsPerSet.count, exStates[i].repsPerSet[s] > 1 { exStates[i].repsPerSet[s] -= 1 }
                                }
                                Text("\(s < exStates[i].repsPerSet.count ? exStates[i].repsPerSet[s] : 10)")
                                    .font(.system(size: 15, weight: .bold)).foregroundColor(.acidGreen).frame(minWidth: 30)
                                stepButton(icon: "plus") {
                                    if s < exStates[i].repsPerSet.count { exStates[i].repsPerSet[s] += 1 }
                                }
                            }
                        }
                    }
                } else {
                    HStack(spacing: 14) {
                        stepButton(icon: "minus") { if exStates[i].uniformReps > 1 { exStates[i].uniformReps -= 1 } }
                        Text("\(exStates[i].uniformReps)").font(.system(size: 16, weight: .bold)).foregroundColor(.white).frame(minWidth: 30)
                        stepButton(icon: "plus") { exStates[i].uniformReps += 1 }
                        Spacer()
                    }
                }
            }.padding(10).background(fieldBg)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: corner).fill(Color.acidGreen.opacity(0.04))
            .overlay(RoundedRectangle(cornerRadius: corner).stroke(Color.acidGreen.opacity(0.15), lineWidth: 1)))
    }

    // MARK: - Helpers

    private func save() {
        let exercises = exStates.map { s in
            WorkoutPlanExercise(
                name: s.name.trimmingCharacters(in: .whitespaces),
                sets: s.sets, repsBySet: s.resolvedReps, isBodyweight: false
            )
        }
        item.superset = WorkoutPlanSuperset(
            id: item.superset?.id ?? UUID().uuidString,
            name: supersetName, exercises: exercises, restAfterSeconds: restSeconds
        )
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }

    private func label(_ text: String) -> some View {
        Text(text).font(.caption).fontWeight(.bold).foregroundColor(.acidGreen).tracking(1)
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
            Image(systemName: icon).font(.system(size: 14, weight: .bold)).foregroundColor(.acidGreen)
                .frame(width: 32, height: 32).background(Circle().fill(Color.acidGreen.opacity(0.15)))
        }
    }
}
