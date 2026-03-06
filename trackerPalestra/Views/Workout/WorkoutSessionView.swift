import SwiftUI
import Combine
import UniformTypeIdentifiers

// MARK: - SessionItem
private enum SessionItem: Identifiable {
    case single(indices: [Int])
    case superset(indices: [Int], groupId: String, name: String, isCircuit: Bool)

    var id: String {
        switch self {
        case .single(let idx): return "s_\(idx[0])"
        case .superset(_, let gid, _, _): return "ss_\(gid)"
        }
    }
}

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
    @State private var currentRestLabel: String = "RECUPERO"

    @State private var supersetSetTracker: [String: [Int: Int]] = [:]

    private let ssColor  = Color.orange
    private let cirColor = Color.cyan

    init(session: WorkoutSession, onSave: @escaping (WorkoutSession) -> Void) {
        _localSession = State(initialValue: session)
        self.onSave = onSave
    }

    private var sessionItems: [SessionItem] {
        var result: [SessionItem] = []
        var i = 0
        while i < localSession.exercises.count {
            let ex = localSession.exercises[i]
            if let gid = ex.supersetGroupId {
                var indices = [i]
                var j = i + 1
                while j < localSession.exercises.count,
                      localSession.exercises[j].supersetGroupId == gid {
                    indices.append(j); j += 1
                }
                let isCircuit = ex.isCircuit ?? false
                result.append(.superset(indices: indices, groupId: gid,
                                        name: ex.supersetName ?? "Superset",
                                        isCircuit: isCircuit))
                i = j
            } else {
                result.append(.single(indices: [i]))
                i += 1
            }
        }
        return result
    }

    private var workoutProgress: Double {
        let allSets = localSession.exercises.flatMap { $0.sets }
        if allSets.isEmpty { return 0.0 }
        let completed = allSets.filter { $0.isCompleted }.count
        return Double(completed) / Double(allSets.count)
    }

    var body: some View {
        ZStack {
            Color.customBlack.ignoresSafeArea()
                .onTapGesture { hideKeyboard() }

            VStack(spacing: 0) {
                compactHeaderView

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // Data e Note
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.acidGreen)
                                DatePicker("", selection: $localSession.date, displayedComponents: .date)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                                Spacer()
                            }
                            
                            Divider().background(Color.white.opacity(0.1))
                            
                            HStack(alignment: .top) {
                                Image(systemName: "pencil.line")
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding(.top, 8)
                                TextEditor(text: $localSession.notes)
                                    .frame(height: 50)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)
                                    .overlay(
                                        Text("Aggiungi note generali...")
                                            .font(.system(size: 14))
                                            .foregroundColor(Color.white.opacity(0.3))
                                            .padding(.top, 8)
                                            .padding(.leading, 4)
                                            .opacity(localSession.notes.isEmpty ? 1 : 0)
                                        , alignment: .topLeading
                                    )
                            }
                        }
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.03)))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        // Lista Esercizi
                        ForEach(sessionItems) { item in
                            switch item {
                            case .single(let indices):
                                let idx = indices[0]
                                ExerciseCardView(
                                    exercise: $localSession.exercises[idx],
                                    onDelete: {
                                        withAnimation { localSession.exercises.remove(at: idx) }
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    },
                                    restSeconds: localSession.exercises[idx].restAfterSeconds,
                                    onStartRest: { seconds in
                                        startRest(seconds: seconds, label: localSession.exercises[idx].name)
                                    }
                                )
                                .padding(.horizontal, 16)
                            case .superset(let indices, let gid, let ssName, let isCircuit):
                                supersetGroupView(indices: indices, groupId: gid, name: ssName, isCircuit: isCircuit)
                            }
                        }

                        // Bottoni Aggiungi / Completa
                        VStack(spacing: 16) {
                            Button { hideKeyboard(); showingExtraSheet = true } label: {
                                HStack {
                                    Image(systemName: "plus")
                                    Text("AGGIUNGI ESERCIZIO EXTRA")
                                }
                                .font(.system(size: 14, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.white.opacity(0.15), style: StrokeStyle(lineWidth: 2, dash: [6])))
                                .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Button {
                                onSave(localSession)
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                dismiss()
                            } label: {
                                HStack {
                                    Text("COMPLETA ALLENAMENTO")
                                        .font(.system(size: 15, weight: .black))
                                        .tracking(1)
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.acidGreen)
                                        .shadow(color: Color.acidGreen.opacity(0.3), radius: 10, y: 5)
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
            guard isTimerRunning, remainingSeconds > 0 else { return }
            remainingSeconds -= 1
            if remainingSeconds == 0 {
                isTimerRunning = false
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showFullScreenTimer = false }
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showFullScreenTimer)
    }

    // MARK: - Superset / Circuit UI Rinnovata

    @ViewBuilder
    private func supersetGroupView(indices: [Int], groupId: String, name: String, isCircuit: Bool) -> some View {
        let accent = isCircuit ? cirColor : ssColor
        let chipLabel = isCircuit ? "CIRCUITO" : "SUPERSET"
        let chipIcon  = isCircuit ? "arrow.3.trianglepath" : "link"
        let restSec   = localSession.exercises[indices[0]].restAfterSeconds

        VStack(spacing: 16) {
            // Pillola testata del gruppo pulita (centrale)
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: chipIcon).font(.system(size: 11, weight: .bold))
                    Text(chipLabel).font(.system(size: 10, weight: .black)).tracking(1)
                }
                .foregroundColor(.black)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Capsule().fill(accent))

                Text(name.uppercased())
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .padding(.leading, 4)

                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "timer").font(.system(size: 10, weight: .bold))
                    Text(formatTime(restSec)).font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(accent.opacity(0.8))
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Capsule().stroke(accent.opacity(0.3), lineWidth: 1))
            }
            .padding(.horizontal, 16)

            // Esercizi (nessuna box esterna ingombrante, usiamo le box base ma legate visivamente)
            VStack(spacing: 12) {
                ForEach(Array(indices.enumerated()), id: \.element) { pos, idx in
                    HStack(spacing: 0) {
                        // Connettore visivo laterale snello
                        VStack(spacing: 0) {
                            if pos > 0 { Rectangle().fill(accent.opacity(0.3)).frame(width: 2, height: 20) }
                            else { Spacer().frame(height: 20) }
                            
                            Text(String(UnicodeScalar(65 + pos)!))
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(accent)
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(accent.opacity(0.15)))
                                .overlay(Circle().stroke(accent.opacity(0.5), lineWidth: 1))
                            
                            if pos < indices.count - 1 { Rectangle().fill(accent.opacity(0.3)).frame(width: 2) }
                            else { Spacer() }
                        }
                        .frame(width: 40)
                        
                        ExerciseCardView(
                            exercise: $localSession.exercises[idx],
                            onDelete: {
                                withAnimation { localSession.exercises.remove(at: idx) }
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            },
                            restSeconds: restSec,
                            onStartRest: { seconds in
                                handleSupersetSetCompleted(
                                    groupId: groupId,
                                    exIdx: idx,
                                    allIndices: indices,
                                    restSeconds: seconds,
                                    label: name
                                )
                            },
                            accentColor: accent,
                            isInsideGroup: true
                        )
                    }
                }
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    // MARK: - Timer logic

    private func handleSupersetSetCompleted(
        groupId: String,
        exIdx: Int,
        allIndices: [Int],
        restSeconds: Int,
        label: String
    ) {
        let completedCount = localSession.exercises[exIdx].sets.filter { $0.isCompleted }.count

        if supersetSetTracker[groupId] == nil {
            supersetSetTracker[groupId] = [:]
        }
        supersetSetTracker[groupId]![exIdx] = completedCount

        let counts = allIndices.compactMap { supersetSetTracker[groupId]?[$0] }
        guard counts.count == allIndices.count else { return }
        guard let minCount = counts.min(), minCount > 0 else { return }
        let allEqual = counts.allSatisfy { $0 == minCount }

        if allEqual {
            startRest(seconds: restSeconds, label: label)
            supersetSetTracker[groupId] = [:]
        }
    }

    private func startRest(seconds: Int, label: String) {
        timerValuePreset = seconds
        remainingSeconds = seconds
        isTimerRunning = true
        currentRestLabel = label.uppercased()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showFullScreenTimer = true }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    // MARK: - Header
    private var compactHeaderView: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PROGRESSO")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.1))
                            Capsule()
                                .fill(Color.acidGreen)
                                .frame(width: geo.size.width * CGFloat(workoutProgress))
                                .animation(.spring(), value: workoutProgress)
                        }
                    }
                    .frame(width: 80, height: 6)
                }

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showFullScreenTimer = true
                        if !isTimerRunning { remainingSeconds = timerValuePreset }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "timer")
                            .font(.system(size: 14, weight: .semibold))
                        if isTimerRunning {
                            Text(formatTime(remainingSeconds))
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                .contentTransition(.numericText())
                        } else {
                            Text("TIMER")
                                .font(.system(size: 12, weight: .bold))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(isTimerRunning ? Color.acidGreen : Color.white.opacity(0.1)))
                    .foregroundColor(isTimerRunning ? .black : .acidGreen)
                    .shadow(color: isTimerRunning ? Color.acidGreen.opacity(0.4) : .clear, radius: 8)
                }

                Spacer()

                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            Divider().background(Color.white.opacity(0.1))
        }
        .background(Color.customBlack.opacity(0.95))
    }

    // MARK: - Full Screen Timer
    private var fullScreenTimerView: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()
            VStack(spacing: 40) {
                Spacer()
                Text(currentRestLabel)
                    .font(.system(size: 14, weight: .bold)).foregroundColor(.white.opacity(0.5)).tracking(3)
                ZStack {
                    Circle().stroke(Color.white.opacity(0.05), lineWidth: 20)
                    Circle()
                        .trim(from: 0, to: CGFloat(remainingSeconds) / CGFloat(max(timerValuePreset, 1)))
                        .stroke(Color.acidGreen, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .shadow(color: Color.acidGreen.opacity(0.5), radius: 15)
                        .animation(.linear(duration: 1), value: remainingSeconds)
                    VStack(spacing: 8) {
                        Text(formatTime(remainingSeconds))
                            .font(.system(size: 80, weight: .black, design: .rounded)).foregroundColor(.white)
                        Text(remainingSeconds == 0 ? "COMPLETATO!" : "RECUPERO")
                            .font(.system(size: 16, weight: .black)).foregroundColor(.acidGreen).tracking(2)
                    }
                }
                .frame(width: 300, height: 300)
                Spacer()
                VStack(spacing: 30) {
                    HStack(spacing: 16) {
                        ForEach([30, 60, 90, 120], id: \.self) { seconds in
                            Button {
                                timerValuePreset = seconds
                                remainingSeconds = seconds
                                isTimerRunning = false
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                Text("\(seconds)s")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(timerValuePreset == seconds ? .black : .white)
                                    .frame(width: 65, height: 44)
                                    .background(RoundedRectangle(cornerRadius: 12)
                                        .fill(timerValuePreset == seconds ? Color.acidGreen : Color.white.opacity(0.1)))
                            }
                        }
                    }
                    HStack(spacing: 20) {
                        Button {
                            isTimerRunning = false; remainingSeconds = timerValuePreset
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        } label: {
                            Image(systemName: "arrow.counterclockwise").font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                                .frame(width: 70, height: 70).background(Circle().fill(Color.white.opacity(0.1)))
                        }
                        Button {
                            isTimerRunning.toggle()
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        } label: {
                            Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 32, weight: .black)).foregroundColor(.black)
                                .frame(width: 90, height: 90)
                                .background(Circle().fill(Color.acidGreen).shadow(color: Color.acidGreen.opacity(0.4), radius: 16, y: 8))
                        }
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showFullScreenTimer = false }
                        } label: {
                            Image(systemName: "chevron.down").font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                                .frame(width: 70, height: 70).background(Circle().fill(Color.white.opacity(0.1)))
                        }
                    }
                }
                .padding(.bottom, 60)
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60; let s = seconds % 60
        return m > 0 ? String(format: "%d:%02d", m, s) : "\(s)s"
    }

    private func addExtraExercise(named name: String) {
        let ex = WorkoutExerciseSession(
            exerciseId: UUID().uuidString, name: viewModel.normalizeName(name),
            isBodyweight: false,
            sets: [WorkoutSet(id: UUID().uuidString, setIndex: 0, reps: 10, weight: 0, isPR: false)],
            isPR: false, exerciseNotes: ""
        )
        withAnimation { localSession.exercises.append(ex) }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
