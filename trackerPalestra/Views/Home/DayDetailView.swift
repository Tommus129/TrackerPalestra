import SwiftUI

struct DayDetailView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @Binding var day: WorkoutPlanDay

    @State private var goToAddExercise = false
    @State private var goToAddSuperset = false

    private let corner: CGFloat = 12

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            NavigationLink(
                destination: AddExerciseView(day: $day).environmentObject(viewModel),
                isActive: $goToAddExercise
            ) { EmptyView() }.hidden()

            NavigationLink(
                destination: AddSupersetView(day: $day),
                isActive: $goToAddSuperset
            ) { EmptyView() }.hidden()

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
                    Button {
                        goToAddExercise = true
                    } label: {
                        Label("AGGIUNGI ESERCIZIO", systemImage: "plus")
                            .font(.system(size: 15, weight: .bold))
                            .tracking(0.8)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: corner).fill(Color.acidGreen))
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    Button {
                        goToAddSuperset = true
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
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
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
                ExerciseItemRow(exercise: ex) { removeItem(at: idx) }
            }
        case .superset:
            if let ss = item.superset {
                SupersetItemRow(superset: ss) { removeItem(at: idx) }
            }
        }
    }

    private func removeItem(at idx: Int) {
        guard idx < day.items.count else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            day.items.remove(at: idx)
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
                    .foregroundColor(.acidGreen)
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
                        .foregroundColor(.acidGreen.opacity(0.8))
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
                .fill(Color.acidGreen.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.acidGreen.opacity(0.15), lineWidth: 1))
        )
        .padding(.vertical, 4)
    }
}
