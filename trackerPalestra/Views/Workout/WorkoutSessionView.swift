import SwiftUI
import Combine

struct WorkoutSessionView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @Environment(\.dismiss) var dismiss
    @State private var localSession: WorkoutSession
    var onSave: (WorkoutSession) -> Void

    @State private var remainingSeconds: Int = 60
    @State private var isTimerRunning: Bool = false
    @State private var timerValuePreset: Int = 60
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    @State private var showingExtraSheet = false

    init(session: WorkoutSession, onSave: @escaping (WorkoutSession) -> Void) {
        _localSession = State(initialValue: session)
        self.onSave = onSave
    }

    var body: some View {
        ZStack {
            Color.customBlack.ignoresSafeArea()
            VStack(spacing: 0) {
                // Timer Header
                HStack(spacing: 20) {
                    ZStack {
                        Circle().stroke(Color.deepPurple.opacity(0.2), lineWidth: 6)
                        Circle().trim(from: 0, to: CGFloat(remainingSeconds) / CGFloat(timerValuePreset)).stroke(Color.acidGreen, style: StrokeStyle(lineWidth: 6, lineCap: .round)).rotationEffect(.degrees(-90)).animation(.linear, value: remainingSeconds)
                        Text("\(remainingSeconds)s").font(.system(.title3, design: .monospaced)).fontWeight(.bold).foregroundColor(.white)
                    }.frame(width: 80, height: 80)
                    VStack(alignment: .leading) {
                        Menu { ForEach([30, 60, 90, 120, 180], id: \.self) { v in Button("\(v)s") { timerValuePreset = v; remainingSeconds = v } } } label: { Label("Recupero: \(timerValuePreset)s", systemImage: "timer").font(.caption.bold()).foregroundColor(.acidGreen) }
                        Button(isTimerRunning ? "STOP" : "START") { isTimerRunning.toggle() }.buttonStyle(.borderedProminent).tint(isTimerRunning ? .red : .deepPurple).controlSize(.small)
                    }
                    Spacer()
                }.padding().background(Color.white.opacity(0.05))

                ScrollView {
                    VStack(spacing: 20) {
                        DatePicker("DATA", selection: $localSession.date, displayedComponents: .date).font(.caption.bold()).foregroundColor(.secondary).padding()
                        
                        ForEach(localSession.exercises.indices, id: \.self) { index in
                            ExerciseCardView(exercise: $localSession.exercises[index], onDelete: {
                                localSession.exercises.remove(at: index)
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            })
                        }
                    }
                }

                VStack(spacing: 12) {
                    Button("AGGIUNGI ESERCIZIO EXTRA") {
                        showingExtraSheet = true
                    }
                    .foregroundColor(.white).font(.footnote.bold())

                    Button("SALVA ALLENAMENTO") {
                        onSave(localSession)
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent).tint(Color.acidGreen).foregroundColor(.black).fontWeight(.black).frame(maxWidth: .infinity)
                }.padding().background(Color.customBlack)
            }
        }
        .onAppear { viewModel.loadExerciseNames() }
        .sheet(isPresented: $showingExtraSheet) {
            // RECUPERA ESERCIZI DALLA LIBRERIA AGGIORNATA
            ExtraExerciseSheet(allNames: viewModel.exerciseNames) { name in
                addExtraExercise(named: name)
                showingExtraSheet = false
            }
        }
    }

    private func addExtraExercise(named name: String) {
        let ex = WorkoutExerciseSession(exerciseId: UUID().uuidString, name: viewModel.normalizeName(name), isBodyweight: false, sets: [WorkoutSet(setIndex: 0, reps: 10, weight: 0, isPR: false)], isPR: false, exerciseNotes: "")
        localSession.exercises.append(ex)
    }
}
