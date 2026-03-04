import SwiftUI

struct DayDetailView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @Binding var day: WorkoutPlanDay

    @State private var goToAddExercise = false
    @State private var goToAddSuperset = false
    @State private var editingExerciseIdx: Int? = nil
    @State private var editingSupersetIdx: Int? = nil

    private let corner: CGFloat = 12

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            NavigationLink(
                destination: AddExerciseView(day: $day).environmentObject(viewModel),
                isActive: $goToAddExercise
            ) { EmptyView() }.hidden()

            NavigationLink(
                destination: AddSupersetView(day: $day).environmentObject(viewModel),
                isActive: $goToAddSuperset
            ) { EmptyView() }.hidden()

            if let idx = editingExerciseIdx, idx < day.items.count, day.items[idx].exercise != nil {
                NavigationLink(
                    destination: EditExerciseView(item: $day.items[idx])
                        .environmentObject(viewModel),
                    isActive: Binding(
                        get: { editingExerciseIdx != nil },
                        set: { if !$0 { editingExerciseIdx = nil } }
                    )
                ) { EmptyView() }.hidden()
            }

            if let idx = editingSupersetIdx, idx < day.items.count, day.items[idx].superset != nil {
                NavigationLink(
                    destination: EditSupersetView(item: $day.items[idx])
                        .environmentObject(viewModel),
                    isActive: Binding(
                        get: { editingSupersetIdx != nil },
                        set: { if !$0 { editingSupersetIdx = nil } }
                    )
                ) { EmptyView() }.hidden()
            }

            List {
                Section {
                    TextField("Nome giorno", text: $day.label)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.vertical, 4)
                        .accentColor(.acidGreen)
                } header: { sectionHeader(icon: "calendar", title: "NOME GIORNO") }
                .listRowBackground(rowBg)
                .listRowSeparator(.hidden)

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

                Section {
                    Button { goToAddExercise = true } label: {
                        Label("AGGIUNGI ESERCIZIO", systemImage: "plus")
                            .font(.system(size: 15, weight: .bold)).tracking(0.8)
                            .foregroundColor(.black).frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: corner).fill(Color.acidGreen))
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear).listRowSeparator(.hidden)

                    Button { goToAddSuperset = true } label: {
                        Label("AGGIUNGI SUPERSET", systemImage: "link")
                            .font(.system(size: 15, weight: .bold)).tracking(0.8)
                            .foregroundColor(.acidGreen).frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: corner).strokeBorder(Color.acidGreen, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear).listRowSeparator(.hidden)
                }
            }
            .scrollContentBackground(.hidden)
            .environment(\.editMode, .constant(.active))
        }
        .navigationTitle(day.label)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear { migrateLegacyIfNeeded() }
    }

    @ViewBuilder
    private func itemRow(idx: Int) -> some View {
        let item = day.items[idx]
        switch item.kind {
        case .exercise:
            if let ex = item.exercise {
                ExerciseItemRow(exercise: ex) {
                    editingExerciseIdx = idx
                }
                .contentShape(Rectangle())
            }
        case .superset:
            if let ss = item.superset {
                SupersetItemRow(superset: ss) {
                    editingSupersetIdx = idx
                }
                .contentShape(Rectangle())
            }
        }
    }

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
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
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
                            Text("BW").font(.caption2).fontWeight(.black).foregroundColor(.black)
                                .padding(.horizontal, 6).padding(.vertical, 3)
                                .background(Capsule().fill(Color.acidGreen))
                        }
                        HStack(spacing: 3) {
                            Image(systemName: "timer").font(.system(size: 8, weight: .bold))
                            Text(formatRest(exercise.restAfterSeconds))
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(Capsule().fill(Color.white.opacity(0.08)))
                    }
                    if !exercise.notes.isEmpty {
                        Text(exercise.notes).font(.caption).foregroundColor(.gray).lineLimit(1)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.25))
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private func formatRest(_ s: Int) -> String {
        s < 60 ? "\(s)s" : (s % 60 == 0 ? "\(s/60)m" : "\(s/60)m\(s%60)s")
    }
}

// MARK: - SupersetItemRow
struct SupersetItemRow: View {
    let superset: WorkoutPlanSuperset
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(superset.name, systemImage: "link")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.acidGreen)
                    Spacer()
                    Text("Rec. \(superset.restAfterSeconds)\"")
                        .font(.caption).foregroundColor(.gray)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.25))
                }
                ForEach(superset.exercises.indices, id: \.self) { i in
                    let ex = superset.exercises[i]
                    HStack(spacing: 10) {
                        Text("\(i + 1).")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.acidGreen.opacity(0.8)).frame(width: 18)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ex.name)
                                .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                            Text("\(ex.sets) × \(ex.repsDisplay)")
                                .font(.system(size: 13, weight: .bold)).foregroundColor(.acidGreen)
                        }
                        Spacer()
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.acidGreen.opacity(0.05))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.acidGreen.opacity(0.15), lineWidth: 1))
            )
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
