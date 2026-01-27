import SwiftUI

struct WorkoutSessionView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @Environment(\.dismiss) var dismiss

    @State private var localSession: WorkoutSession

    // callback verso il ViewModel
    var onSave: (WorkoutSession) -> Void

    // Timer
    @State private var remainingSeconds: Int = 60
    @State private var isTimerRunning: Bool = false
    @State private var timerValuePreset: Int = 60

    // Extra exercise sheet
    @State private var showingExtraSheet = false

    init(session: WorkoutSession, onSave: @escaping (WorkoutSession) -> Void) {
        _localSession = State(initialValue: session)
        self.onSave = onSave
    }

    var body: some View {
        VStack {
            // Data allenamento
            HStack {
                Text("Data allenamento:")
                    .font(.subheadline)
                DatePicker(
                    "",
                    selection: $localSession.date,
                    displayedComponents: .date
                )
                .labelsHidden()
            }
            .padding(.horizontal)

            // Timer barra in alto
            HStack {
                Text("Recupero: \(remainingSeconds)s")
                    .font(.headline)
                    .foregroundColor(isTimerRunning ? .green : .primary)

                Spacer()

                Menu("\(timerValuePreset)s") {
                    ForEach([30, 60, 90, 120], id: \.self) { value in
                        Button("\(value)s") {
                            timerValuePreset = value
                            remainingSeconds = value
                        }
                    }
                }

                Button(isTimerRunning ? "Stop" : "Start") {
                    if isTimerRunning {
                        stopTimer()
                    } else {
                        startTimer()
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding()

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(localSession.exercises.indices, id: \.self) { index in
                        ExerciseCardView(exercise: $localSession.exercises[index])
                    }

                    VStack(alignment: .leading) {
                        Text("Note allenamento")
                            .font(.headline)
                        TextEditor(text: $localSession.notes)
                            .frame(minHeight: 80)
                            .border(Color.gray.opacity(0.3))
                    }
                    .padding(.horizontal)
                }
            }

            Button("Aggiungi esercizio extra") {
                showingExtraSheet = true
            }
            .padding(.horizontal)
            .sheet(isPresented: $showingExtraSheet) {
                ExtraExerciseSheet(
                    allNames: availableExerciseNames,
                    onSelect: { name in
                        addExtraExercise(named: name)
                        showingExtraSheet = false
                    }
                )
            }

            Button("Salva allenamento") {
                onSave(localSession)
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .navigationTitle("Allenamento")
    }

    // MARK: - Nomi disponibili per extra

    private var availableExerciseNames: [String] {
        var setNames = Set<String>()

        // nomi globali da Firestore (schede + sessioni salvate)
        setNames.formUnion(viewModel.exerciseNames)

        // nomi dagli esercizi della sessione corrente
        setNames.formUnion(localSession.exercises.map { $0.name })

        return Array(setNames).sorted()
    }

    // MARK: - Azioni esercizi

    private func addExtraExercise(named name: String) {
        let extraExerciseId = UUID().uuidString

        let exerciseSession = WorkoutExerciseSession(
            exerciseId: extraExerciseId,
            name: name,
            isBodyweight: false,
            sets: [
                WorkoutSet(
                    id: UUID().uuidString,
                    setIndex: 0,
                    reps: 8,
                    weight: 0,
                    setNotes: nil,
                    isPR: false
                )
            ],
            isPR: false,
            exerciseNotes: ""
        )

        localSession.exercises.append(exerciseSession)
    }

    // MARK: - Timer

    func startTimer() {
        remainingSeconds = timerValuePreset
        isTimerRunning = true

        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if !isTimerRunning {
                timer.invalidate()
                return
            }

            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                isTimerRunning = false
                timer.invalidate()
            }
        }
    }

    func stopTimer() {
        isTimerRunning = false
    }
}

