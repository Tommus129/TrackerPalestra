import SwiftUI

struct AddExerciseView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @Environment(\.dismiss) var dismiss
    @Binding var day: WorkoutPlanDay

    @State private var name = ""
    @State private var notes = ""
    @State private var sets = 3
    @State private var variableReps = false
    @State private var uniformReps = 8
    @State private var repsPerSet: [Int] = Array(repeating: 8, count: 3)
    @State private var isBodyweight = false
    @State private var restSeconds = 60

    private let corner: CGFloat = 12

    var suggestions: [String] {
        guard !name.isEmpty else { return [] }
        return viewModel.exerciseNames.filter {
            $0.lowercased().contains(name.lowercased()) && $0.lowercased() != name.lowercased()
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    nameSection
                    setsSection
                    repsSection
                    bodyweightToggle
                    restSection
                    notesSection
                    saveButton
                }
                .padding()
            }
        }
        .navigationTitle("Nuovo Esercizio")
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
            label("NOME ESERCIZIO")
            TextField("Es. Hack Squat", text: $name)
                .foregroundColor(.white).padding(14).background(fieldBg).accentColor(.acidGreen)
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
                stepButton(icon: "minus") {
                    if sets > 1 {
                        sets -= 1
                        if repsPerSet.count > sets {
                            repsPerSet.removeLast()
                        }
                    }
                }
                Text("\(sets)").font(.title2).fontWeight(.bold).foregroundColor(.white).frame(minWidth: 40)
                stepButton(icon: "plus") {
                    if sets < 10 {
                        sets += 1
                        if repsPerSet.count < sets {
                            repsPerSet.append(repsPerSet.last ?? 8)
                        }
                    }
                }
                Spacer()
            }
            .padding(14).background(fieldBg)
        }
    }

    private var repsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                label("RIPETIZIONI")
                Spacer()
                Toggle("", isOn: $variableReps).labelsHidden().tint(.acidGreen)
                Text("Diverse per serie").font(.caption).foregroundColor(.gray)
            }
            if variableReps {
                VStack(spacing: 8) {
                    ForEach(repsPerSet.indices, id: \.self) { i in
                        HStack {
                            Text("Serie \(i + 1)")
                                .font(.system(size: 13)).foregroundColor(.gray)
                                .frame(width: 60, alignment: .leading)
                            Spacer()
                            stepButton(icon: "minus") {
                                if repsPerSet[i] > 1 { repsPerSet[i] -= 1 }
                            }
                            Text("\(repsPerSet[i])")
                                .font(.system(size: 17, weight: .bold)).foregroundColor(.acidGreen).frame(minWidth: 34)
                            stepButton(icon: "plus") {
                                repsPerSet[i] += 1
                            }
                        }
                        .padding(.horizontal, 14).padding(.vertical, 10).background(fieldBg)
                    }
                }
                .onChange(of: variableReps) { on in
                    if on {
                        // Allinea la lunghezza dell'array a 'sets' mantenendo i vecchi valori, o usa uniformReps per i nuovi
                        if repsPerSet.count < sets {
                            let diff = sets - repsPerSet.count
                            repsPerSet.append(contentsOf: Array(repeating: uniformReps, count: diff))
                        } else if repsPerSet.count > sets {
                            repsPerSet = Array(repsPerSet.prefix(sets))
                        }
                    }
                }
            } else {
                HStack(spacing: 16) {
                    stepButton(icon: "minus") { if uniformReps > 1 { uniformReps -= 1 } }
                    Text("\(uniformReps)").font(.title2).fontWeight(.bold).foregroundColor(.white).frame(minWidth: 40)
                    stepButton(icon: "plus") { uniformReps += 1 }
                    Spacer()
                }
                .padding(14).background(fieldBg)
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
                    .font(.system(size: 15, weight: .medium)).foregroundColor(.white.opacity(0.85))
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

    private var restSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("RECUPERO TRA LE SERIE")
            HStack(spacing: 16) {
                stepButton(icon: "minus") { if restSeconds >= 15 { restSeconds -= 15 } }
                HStack(spacing: 4) {
                    Text(formatRest(restSeconds))
                        .font(.title2).fontWeight(.bold).foregroundColor(.white)
                    Text(restSeconds >= 60 ? "min" : "sec")
                        .font(.caption).foregroundColor(.gray)
                }
                .frame(minWidth: 70)
                stepButton(icon: "plus") { restSeconds += 15 }
                Spacer()
            }
            .padding(14).background(fieldBg)
            HStack(spacing: 8) {
                ForEach([30, 60, 90, 120, 180], id: \.self) { sec in
                    Button { restSeconds = sec } label: {
                        Text(sec < 60 ? "\(sec)s" : "\(sec/60)m\(sec%60 > 0 ? "\(sec%60)s" : "")")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(restSeconds == sec ? .black : .acidGreen)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(
                                Capsule().fill(restSeconds == sec ? Color.acidGreen : Color.acidGreen.opacity(0.1))
                            )
                    }
                }
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("NOTE")
            TextField("Es. recupero lungo, cadenza lenta", text: $notes, axis: .vertical)
                .foregroundColor(.white).padding(14).background(fieldBg).lineLimit(2...4).accentColor(.acidGreen)
        }
    }

    private var saveButton: some View {
        Button(action: save) {
            Text("AGGIUNGI ESERCIZIO")
                .font(.system(size: 15, weight: .bold)).tracking(0.8)
                .foregroundColor(name.trimmingCharacters(in: .whitespaces).isEmpty ? .gray.opacity(0.4) : .black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: corner)
                        .fill(name.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray.opacity(0.2) : Color.acidGreen)
                )
        }
        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private func formatRest(_ s: Int) -> String {
        if s < 60 { return "\(s)" }
        let m = s / 60; let sec = s % 60
        return sec == 0 ? "\(m):00" : "\(m):\(String(format:"%02d",sec))"
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
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold)).foregroundColor(.acidGreen)
                .frame(width: 36, height: 36).background(Circle().fill(Color.acidGreen.opacity(0.15)))
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let finalReps: [Int] = variableReps ? Array(repsPerSet.prefix(sets)) : [uniformReps]
        let ex = WorkoutPlanExercise(
            name: viewModel.normalizeName(trimmed),
            sets: sets,
            repsBySet: finalReps,
            isBodyweight: isBodyweight,
            notes: notes,
            restAfterSeconds: restSeconds
        )
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            day.items.append(WorkoutPlanItem(kind: .exercise, exercise: ex))
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}
