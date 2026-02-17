import SwiftUI
import Combine
import UniformTypeIdentifiers

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
    @State private var showFullScreenTimer = false

    init(session: WorkoutSession, onSave: @escaping (WorkoutSession) -> Void) {
        _localSession = State(initialValue: session)
        self.onSave = onSave
    }

    var body: some View {
        ZStack {
            Color.customBlack.ignoresSafeArea()
                .onTapGesture { hideKeyboard() }
            
            VStack(spacing: 0) {
                // Header Compatto
                compactHeaderView

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

                        // Lista Esercizi con Drag & Drop
                        ForEach(Array(localSession.exercises.enumerated()), id: \.element.id) { index, exercise in
                            ExerciseCardView(exercise: $localSession.exercises[index], onDelete: {
                                withAnimation {
                                    localSession.exercises.remove(at: index)
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                }
                            })
                            .onDrag {
                                return NSItemProvider(object: String(index) as NSString)
                            }
                            .onDrop(of: [UTType.text], delegate: ExerciseDropDelegate(
                                exercises: $localSession.exercises,
                                draggedIndex: index
                            ))
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

                        // Bottoni
                        VStack(spacing: 15) {
                            Button {
                                hideKeyboard()
                                showingExtraSheet = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 16))
                                    Text("AGGIUNGI ESERCIZIO")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.acidGreen.opacity(0.3), lineWidth: 2)
                                )
                                .foregroundColor(.acidGreen)
                            }

                            Button {
                                onSave(localSession)
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18))
                                    Text("COMPLETA ALLENAMENTO")
                                        .font(.system(size: 13, weight: .black))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.acidGreen)
                                        .shadow(color: Color.acidGreen.opacity(0.3), radius: 8, y: 4)
                                )
                                .foregroundColor(.black)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 30)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            
            // Full Screen Timer Overlay
            if showFullScreenTimer {
                fullScreenTimerView
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(999)
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
                if remainingSeconds == 0 {
                    isTimerRunning = false
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    // Auto-dismiss dopo 2 secondi
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showFullScreenTimer = false
                        }
                    }
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showFullScreenTimer)
    }

    private var compactHeaderView: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showFullScreenTimer = true
                    if !isTimerRunning {
                        remainingSeconds = timerValuePreset
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "timer")
                        .font(.system(size: 16))
                    Text("RECUPERO")
                        .font(.system(size: 11, weight: .bold))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.deepPurple)
                )
                .foregroundColor(.acidGreen)
            }
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.02))
    }

    private var fullScreenTimerView: some View {
        ZStack {
            Color.black.opacity(0.95)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Timer Circolare Grande
                ZStack {
                    Circle()
                        .stroke(Color.deepPurple.opacity(0.2), lineWidth: 16)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(remainingSeconds) / CGFloat(timerValuePreset))
                        .stroke(Color.acidGreen, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .shadow(color: Color.acidGreen.opacity(0.6), radius: 12)
                        .animation(.linear(duration: 1), value: remainingSeconds)
                    
                    VStack(spacing: 8) {
                        Text(formatTime(remainingSeconds))
                            .font(.system(size: 72, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(remainingSeconds == 0 ? "COMPLETATO!" : "RECUPERO")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.acidGreen)
                            .tracking(2)
                    }
                }
                .frame(width: 280, height: 280)
                
                Spacer()
                
                // Controlli Timer
                VStack(spacing: 20) {
                    // Preset Tempo Rapido
                    HStack(spacing: 12) {
                        ForEach([30, 60, 90, 120], id: \.self) { seconds in
                            Button {
                                timerValuePreset = seconds
                                remainingSeconds = seconds
                                isTimerRunning = false
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                Text("\(seconds)s")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(timerValuePreset == seconds ? .black : .acidGreen)
                                    .frame(width: 70, height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(timerValuePreset == seconds ? Color.acidGreen : Color.deepPurple.opacity(0.3))
                                    )
                            }
                        }
                    }
                    
                    // Pulsanti Principali
                    HStack(spacing: 15) {
                        // Reset
                        Button {
                            isTimerRunning = false
                            remainingSeconds = timerValuePreset
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 70, height: 70)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                )
                        }
                        
                        // Play/Pause
                        Button {
                            isTimerRunning.toggle()
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        } label: {
                            Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.black)
                                .frame(width: 90, height: 90)
                                .background(
                                    Circle()
                                        .fill(Color.acidGreen)
                                        .shadow(color: Color.acidGreen.opacity(0.5), radius: 16, y: 8)
                                )
                        }
                        
                        // Chiudi
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showFullScreenTimer = false
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 70, height: 70)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                )
                        }
                    }
                }
                .padding(.bottom, 50)
            }
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        if mins > 0 {
            return String(format: "%d:%02d", mins, secs)
        } else {
            return "\(secs)"
        }
    }

    private func addExtraExercise(named name: String) {
        let ex = WorkoutExerciseSession(
            exerciseId: UUID().uuidString,
            name: viewModel.normalizeName(name),
            isBodyweight: false,
            sets: [WorkoutSet(id: UUID().uuidString, setIndex: 0, reps: 10, weight: 0, isPR: false)],
            isPR: false,
            exerciseNotes: ""
        )
        withAnimation {
            localSession.exercises.append(ex)
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Drag & Drop Delegate
struct ExerciseDropDelegate: DropDelegate {
    @Binding var exercises: [WorkoutExerciseSession]
    let draggedIndex: Int
    
    func performDrop(info: DropInfo) -> Bool {
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let itemProvider = info.itemProviders(for: [UTType.text]).first else { return }
        
        itemProvider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { (item, error) in
            guard let data = item as? Data,
                  let sourceIndexString = String(data: data, encoding: .utf8),
                  let sourceIndex = Int(sourceIndexString),
                  sourceIndex != draggedIndex else { return }
            
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    let sourceExercise = exercises[sourceIndex]
                    exercises.remove(at: sourceIndex)
                    
                    let destinationIndex = sourceIndex < draggedIndex ? draggedIndex - 1 : draggedIndex
                    exercises.insert(sourceExercise, at: destinationIndex)
                    
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }
        }
    }
}
