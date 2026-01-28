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
                .onTapGesture { hideKeyboard() }
            
            VStack(spacing: 0) {
                // Timer Header
                timerHeaderView

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        // Data Picker
                        HStack {
                            Image(systemName: "calendar")
                            DatePicker("", selection: $localSession.date, displayedComponents: .date)
                                .labelsHidden()
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.white.opacity(0.05)))
                        .padding(.top, 20)

                        // Lista Esercizi
                        ForEach(localSession.exercises.indices, id: \.self) { index in
                            ExerciseCardView(exercise: $localSession.exercises[index], onDelete: {
                                localSession.exercises.remove(at: index)
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            })
                        }

                        // Note Generali
                        VStack(alignment: .leading, spacing: 10) {
                            Text("NOTE GENERALI ALLENAMENTO")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(.acidGreen)
                                .tracking(2)
                            
                            TextEditor(text: $localSession.notes)
                                .frame(height: 100)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.deepPurple.opacity(0.3), lineWidth: 1))
                                .scrollContentBackground(.hidden)
                        }
                        .padding(.horizontal, 16)

                        // --- BOTTONI BLOCCATI A FINE PAGINA (Dentro ScrollView) ---
                        VStack(spacing: 15) {
                            Button("AGGIUNGI ESERCIZIO EXTRA") {
                                hideKeyboard()
                                showingExtraSheet = true
                            }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.acidGreen.opacity(0.8))

                            Button("COMPLETA ALLENAMENTO") {
                                onSave(localSession)
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color.acidGreen)
                            .foregroundColor(.black)
                            .fontWeight(.black)
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 30)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .onAppear { viewModel.loadExerciseNames() }
        .sheet(isPresented: $showingExtraSheet) {
            ExtraExerciseSheet(allNames: viewModel.exerciseNames) { name in
                addExtraExercise(named: name)
                showingExtraSheet = false
            }
        }
        .onReceive(timer) { _ in
            if isTimerRunning && remainingSeconds > 0 {
                remainingSeconds -= 1
            } else if remainingSeconds == 0 {
                isTimerRunning = false
            }
        }
    }

    private var timerHeaderView: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle().stroke(Color.deepPurple.opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: CGFloat(remainingSeconds) / CGFloat(timerValuePreset))
                    .stroke(Color.acidGreen, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Color.acidGreen.opacity(0.5), radius: 6)
                Text("\(remainingSeconds)s").font(.system(.title2, design: .monospaced)).fontWeight(.black).foregroundColor(.white)
            }
            .frame(width: 80, height: 80)
            
            VStack(alignment: .leading, spacing: 10) {
                Menu {
                    ForEach([30, 45, 60, 90, 120, 180], id: \.self) { v in
                        Button("\(v)s") { timerValuePreset = v; remainingSeconds = v }
                    }
                } label: {
                    Label("RECUPERO: \(timerValuePreset)s", systemImage: "timer")
                        .font(.system(size: 10, weight: .black)).foregroundColor(.acidGreen)
                }
                
                Button(action: { isTimerRunning.toggle() }) {
                    Text(isTimerRunning ? "PAUSE" : "START REST")
                        .font(.system(size: 11, weight: .black))
                        .padding(.horizontal, 15).padding(.vertical, 6)
                        .background(isTimerRunning ? Color.red.opacity(0.2) : Color.deepPurple)
                        .foregroundColor(.white).cornerRadius(8)
                }
            }
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.02))
    }

    private func addExtraExercise(named name: String) {
        let ex = WorkoutExerciseSession(exerciseId: UUID().uuidString, name: viewModel.normalizeName(name), isBodyweight: false, sets: [WorkoutSet(id: UUID().uuidString, setIndex: 0, reps: 10, weight: 0, isPR: false)], isPR: false, exerciseNotes: "")
        localSession.exercises.append(ex)
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
