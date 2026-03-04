import SwiftUI

// MARK: - Helpers locali
private enum DetailItem: Identifiable {
    case single(WorkoutExerciseSession)
    case superset(exercises: [WorkoutExerciseSession], groupId: String, name: String)

    var id: String {
        switch self {
        case .single(let ex): return "s_\(ex.id)"
        case .superset(_, let gid, _): return "ss_\(gid)"
        }
    }
}

private func buildItems(from exercises: [WorkoutExerciseSession]) -> [DetailItem] {
    var result: [DetailItem] = []
    var i = 0
    while i < exercises.count {
        let ex = exercises[i]
        if let gid = ex.supersetGroupId {
            var group = [ex]
            var j = i + 1
            while j < exercises.count, exercises[j].supersetGroupId == gid {
                group.append(exercises[j]); j += 1
            }
            result.append(.superset(exercises: group, groupId: gid, name: ex.supersetName ?? "Superset"))
            i = j
        } else {
            result.append(.single(ex))
            i += 1
        }
    }
    return result
}

// MARK: - View principale

struct WorkoutSessionDetailView: View {
    let session: WorkoutSession
    private let ssColor = Color.orange
    private let corner: CGFloat = 16

    private var items: [DetailItem] { buildItems(from: session.exercises) }

    var body: some View {
        ZStack {
            Color.customBlack.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // ── Info sessione
                    infoCard

                    // ── Note
                    if !session.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        notesCard
                    }

                    // ── Esercizi
                    Text("ESERCIZI")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.acidGreen)
                        .tracking(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 4)

                    ForEach(items) { item in
                        switch item {
                        case .single(let ex):
                            exerciseCard(ex, accentColor: .acidGreen)
                        case .superset(let exList, _, let name):
                            supersetCard(exercises: exList, name: name)
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top, 20)
            }
        }
        .navigationTitle("Dettaglio allenamento")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.customBlack, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    // MARK: - Info Card
    private var infoCard: some View {
        HStack(spacing: 20) {
            infoChip(icon: "calendar", label: formatDate(session.date))
            Divider().frame(height: 30).background(Color.white.opacity(0.1))
            infoChip(icon: "dumbbell.fill", label: "\(session.exercises.count) esercizi")
            Divider().frame(height: 30).background(Color.white.opacity(0.1))
            let totalSets = session.exercises.reduce(0) { $0 + $1.sets.count }
            infoChip(icon: "square.3.layers.3d", label: "\(totalSets) set")
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: corner).fill(Color.white.opacity(0.04)))
        .overlay(RoundedRectangle(cornerRadius: corner).stroke(Color.white.opacity(0.07), lineWidth: 1))
        .padding(.horizontal, 16)
    }

    private func infoChip(icon: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 11, weight: .bold)).foregroundColor(.acidGreen)
            Text(label).font(.system(size: 12, weight: .semibold)).foregroundColor(.white.opacity(0.75))
        }
    }

    // MARK: - Notes Card
    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NOTE").font(.system(size: 10, weight: .black)).foregroundColor(.acidGreen).tracking(2)
            Text(session.notes)
                .font(.system(size: 14)).foregroundColor(.white.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: corner).fill(Color.white.opacity(0.04)))
        .overlay(RoundedRectangle(cornerRadius: corner).stroke(Color.white.opacity(0.07), lineWidth: 1))
        .padding(.horizontal, 16)
    }

    // MARK: - Exercise Card (esercizio singolo)
    private func exerciseCard(_ ex: WorkoutExerciseSession, accentColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(accentColor.opacity(0.12)).frame(width: 36, height: 36)
                    Image(systemName: ex.isBodyweight ? "figure.flexibility" : "dumbbell.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(accentColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(ex.name.uppercased())
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.white)
                    Text("\(ex.sets.count) serie")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                }
                Spacer()
                if ex.isPR {
                    Label("PR", systemImage: "trophy.fill")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Capsule().fill(Color.acidGreen))
                }
            }

            // Set table
            VStack(spacing: 6) {
                // Header colonne
                HStack {
                    Text("SET").frame(width: 28, alignment: .leading)
                    Text("REPS").frame(width: 50, alignment: .center)
                    if !ex.isBodyweight { Text("KG").frame(width: 60, alignment: .center) }
                    Spacer()
                    Text("\u2713").frame(width: 24, alignment: .center)
                }
                .font(.system(size: 9, weight: .black))
                .foregroundColor(.white.opacity(0.3))
                .padding(.horizontal, 4)

                ForEach(ex.sets) { set in
                    HStack {
                        Text("\(set.setIndex + 1)")
                            .frame(width: 28, alignment: .leading)
                            .foregroundColor(accentColor.opacity(0.8))
                        Text("\(set.reps)")
                            .frame(width: 50, alignment: .center)
                            .foregroundColor(.white)
                        if !ex.isBodyweight {
                            Text(set.weight > 0 ? String(format: "%.1f", set.weight) : "-")
                                .frame(width: 60, alignment: .center)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Spacer()
                        Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 14))
                            .foregroundColor(set.isCompleted ? accentColor : .white.opacity(0.15))
                            .frame(width: 24)
                    }
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(set.isCompleted ? accentColor.opacity(0.06) : Color.clear)
                    )
                }
            }

            // Note esercizio
            if !ex.exerciseNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                HStack(spacing: 6) {
                    Rectangle().fill(accentColor.opacity(0.4)).frame(width: 2)
                    Text(ex.exerciseNotes)
                        .font(.system(size: 12)).foregroundColor(.white.opacity(0.5)).italic()
                }
                .padding(.top, 2)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: corner).fill(Color.white.opacity(0.04)))
        .overlay(RoundedRectangle(cornerRadius: corner).stroke(Color.white.opacity(0.07), lineWidth: 1))
        .padding(.horizontal, 16)
    }

    // MARK: - Superset Card
    private func supersetCard(exercises: [WorkoutExerciseSession], name: String) -> some View {
        HStack(spacing: 0) {
            // Accent bar sinistra arancione
            Rectangle()
                .fill(ssColor)
                .frame(width: 4)
                .cornerRadius(2)

            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(spacing: 8) {
                    HStack(spacing: 5) {
                        Image(systemName: "link").font(.system(size: 10, weight: .black))
                        Text("SUPERSET").font(.system(size: 10, weight: .black)).tracking(1)
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 9).padding(.vertical, 5)
                    .background(Capsule().fill(ssColor))

                    Text(name.uppercased())
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Spacer()

                    Text("\(exercises.count) esercizi")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.35))
                }
                .padding(.horizontal, 14).padding(.vertical, 12)

                Rectangle()
                    .fill(ssColor.opacity(0.25))
                    .frame(height: 1)
                    .padding(.horizontal, 14)

                // Esercizi del blocco
                ForEach(Array(exercises.enumerated()), id: \.element.id) { pos, ex in
                    VStack(spacing: 0) {
                        // Label A / B / C + nome
                        HStack(spacing: 8) {
                            Text(String(UnicodeScalar(65 + pos)!))
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(ssColor)
                                .frame(width: 20, height: 20)
                                .background(Circle().fill(ssColor.opacity(0.15)))
                            Text(ex.name.uppercased())
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white.opacity(0.75))
                            Spacer()
                            if ex.isPR {
                                Label("PR", systemImage: "trophy.fill")
                                    .font(.system(size: 9, weight: .black)).foregroundColor(.black)
                                    .padding(.horizontal, 7).padding(.vertical, 3)
                                    .background(Capsule().fill(Color.acidGreen))
                            }
                        }
                        .padding(.horizontal, 14).padding(.top, 14).padding(.bottom, 8)

                        // Tabella set
                        VStack(spacing: 6) {
                            HStack {
                                Text("SET").frame(width: 28, alignment: .leading)
                                Text("REPS").frame(width: 50, alignment: .center)
                                if !ex.isBodyweight { Text("KG").frame(width: 60, alignment: .center) }
                                Spacer()
                                Text("\u2713").frame(width: 24, alignment: .center)
                            }
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(.white.opacity(0.3))
                            .padding(.horizontal, 18)

                            ForEach(ex.sets) { set in
                                HStack {
                                    Text("\(set.setIndex + 1)")
                                        .frame(width: 28, alignment: .leading)
                                        .foregroundColor(ssColor.opacity(0.8))
                                    Text("\(set.reps)")
                                        .frame(width: 50, alignment: .center)
                                        .foregroundColor(.white)
                                    if !ex.isBodyweight {
                                        Text(set.weight > 0 ? String(format: "%.1f", set.weight) : "-")
                                            .frame(width: 60, alignment: .center)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    Spacer()
                                    Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 14))
                                        .foregroundColor(set.isCompleted ? ssColor : .white.opacity(0.15))
                                        .frame(width: 24)
                                }
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .padding(.horizontal, 18).padding(.vertical, 3)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(set.isCompleted ? ssColor.opacity(0.06) : Color.clear)
                                )
                            }
                        }
                        .padding(.bottom, 10)

                        // Note esercizio
                        if !ex.exerciseNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            HStack(spacing: 6) {
                                Rectangle().fill(ssColor.opacity(0.4)).frame(width: 2)
                                Text(ex.exerciseNotes)
                                    .font(.system(size: 12)).foregroundColor(.white.opacity(0.5)).italic()
                            }
                            .padding(.horizontal, 18).padding(.bottom, 8)
                        }

                        // Divisore tra esercizi del superset
                        if pos < exercises.count - 1 {
                            Rectangle()
                                .fill(ssColor.opacity(0.15))
                                .frame(height: 1)
                                .padding(.horizontal, 14)
                        }
                    }
                }

                Spacer(minLength: 14)
            }
        }
        .background(RoundedRectangle(cornerRadius: corner).fill(Color.white.opacity(0.04)))
        .overlay(RoundedRectangle(cornerRadius: corner).stroke(ssColor.opacity(0.3), lineWidth: 1))
        .cornerRadius(corner)
        .padding(.horizontal, 16)
    }

    // MARK: - Helpers
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.locale = Locale(identifier: "it_IT")
        return f.string(from: date)
    }
}
