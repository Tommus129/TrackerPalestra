import SwiftUI

struct PlanDetailView: View {
    @EnvironmentObject var viewModel: MainViewModel
    let plan: WorkoutPlan
    @State private var selectedDayId: String?
    @State private var activeSession: WorkoutSession?
    @State private var showingEdit = false

    @State private var showingDraftAlert = false
    @State private var pendingNewSession: WorkoutSession? = nil

    private var selectedDay: WorkoutPlanDay? {
        let currentPlan = viewModel.plans.first(where: { $0.id == plan.id }) ?? plan
        return currentPlan.days.first { $0.id == selectedDayId }
    }

    private var currentPlan: WorkoutPlan {
        viewModel.plans.first(where: { $0.id == plan.id }) ?? plan
    }

    var body: some View {
        ZStack {
            Color.customBlack.ignoresSafeArea()

            Circle()
                .fill(Color.deepPurple.opacity(0.1))
                .frame(width: 300)
                .blur(radius: 60)
                .offset(x: 100, y: -150)

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("SELEZIONA IL GIORNO")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(.acidGreen)
                            .tracking(3)
                            .padding(.horizontal)

                        ForEach(currentPlan.days) { day in
                            dayButton(day: day)
                        }
                        .padding(.horizontal)

                        if let day = selectedDay {
                            exercisePreview(for: day)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }

                startButton
            }
        }
        .navigationTitle(currentPlan.name.uppercased())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.prepareEditPlan(currentPlan)
                    showingEdit = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.acidGreen)
                }
            }
        }
        .sheet(isPresented: $showingEdit, onDismiss: {
            if let sid = selectedDayId,
               !currentPlan.days.contains(where: { $0.id == sid }) {
                selectedDayId = nil
            }
        }) {
            WorkoutPlanEditView()
                .environmentObject(viewModel)
        }
        .sheet(item: $activeSession) { session in
            WorkoutSessionView(session: session) { saved in
                viewModel.saveSession(saved) { _ in }
            }
            .environmentObject(viewModel)
        }
        .alert("Allenamento in sospeso", isPresented: $showingDraftAlert) {
            Button("Riprendi bozza") {
                if let draft = viewModel.activeDraft {
                    activeSession = draft
                }
            }
            Button("Scarta e inizia nuovo", role: .destructive) {
                viewModel.clearDraft()
                activeSession = pendingNewSession
            }
            Button("Annulla", role: .cancel) { }
        } message: {
            Text("Hai un allenamento precedentemente iniziato e non completato. Cosa vuoi fare?")
        }
    }

    // MARK: - Subviews

    private func dayButton(day: WorkoutPlanDay) -> some View {
        let isSelected = day.id == selectedDayId
        let itemCount = day.resolvedItems.count
        return Button {
            withAnimation(.spring()) { selectedDayId = day.id }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(day.label.uppercased())
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("\(itemCount) ESERCIZI")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.acidGreen)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.acidGreen)
                        .subtleGlow()
                }
            }
            .padding()
            .glassStyle()
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isSelected ? Color.acidGreen : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(CyberButtonStyle())
    }

    private func exercisePreview(for day: WorkoutPlanDay) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("ANTEPRIMA ESERCIZI")
                .font(.system(size: 11, weight: .black))
                .foregroundColor(.acidGreen)
                .tracking(3)
                .padding(.horizontal)
                .padding(.top, 10)

            ForEach(day.resolvedItems) { item in
                switch item.kind {
                case .exercise:
                    if let ex = item.exercise { exerciseRow(ex) }
                case .superset:
                    if let ss = item.superset { supersetRow(ss) }
                }
            }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private func exerciseRow(_ exercise: WorkoutPlanExercise) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(exercise.name.uppercased())
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(.white)
                HStack(spacing: 15) {
                    Label("\(exercise.sets) SERIE", systemImage: "square.3.layers.3d")
                    Label("\(exercise.repsDisplay) REPS", systemImage: "repeat")
                    if exercise.isBodyweight {
                        Image(systemName: "figure.strengthtraining.functional")
                            .foregroundColor(.acidGreen)
                    }
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white.opacity(0.6))
                if !exercise.notes.isEmpty {
                    Text(exercise.notes).font(.system(size: 10)).italic()
                        .foregroundColor(.acidGreen.opacity(0.7)).padding(.top, 2)
                }
            }
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.05), lineWidth: 1))
        .padding(.horizontal)
    }

    private func supersetRow(_ ss: WorkoutPlanSuperset) -> some View {
        let accent: Color = ss.isCircuit ? .cyan : .orange
        let icon = ss.isCircuit ? "arrow.3.trianglepath" : "link"
        let typeLabel = ss.isCircuit ? "CIRCUITO" : "SUPERSET"

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: icon).font(.system(size: 9, weight: .bold))
                    Text(typeLabel).font(.system(size: 9, weight: .black)).tracking(1)
                }
                .foregroundColor(.black)
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(Capsule().fill(accent))

                Text(ss.name.uppercased())
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(accent)
                    .tracking(1)
                Spacer()
                HStack(spacing: 3) {
                    Image(systemName: "timer").font(.system(size: 9))
                    Text("Rec. \(ss.restAfterSeconds)\"")
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.gray)
            }

            ForEach(ss.exercises.indices, id: \.self) { i in
                let ex = ss.exercises[i]
                HStack(spacing: 10) {
                    Text(String(UnicodeScalar(65 + i)!))
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(accent)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(accent.opacity(0.15)))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(ex.name.uppercased())
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(.white)
                        HStack(spacing: 12) {
                            Label("\(ex.sets) SERIE", systemImage: "square.3.layers.3d")
                            Label("\(ex.repsDisplay) REPS", systemImage: "repeat")
                        }
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                    }
                    Spacer()
                }
            }
        }
        .padding()
        .background(accent.opacity(0.04))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(accent.opacity(0.12), lineWidth: 1))
        .padding(.horizontal)
    }

    // MARK: - Start Button
    // FIX C3 follow-up: entrambi i percorsi usano guard let per gestire
    // il caso in cui makeSession restituisca nil (userId non disponibile).
    private var startButton: some View {
        Button {
            guard let day = selectedDay,
                  let newSession = viewModel.makeSession(plan: currentPlan, day: day)
            else { return }

            if viewModel.activeDraft != nil {
                self.pendingNewSession = newSession
                self.showingDraftAlert = true
            } else {
                activeSession = newSession
            }
        } label: {
            HStack {
                Image(systemName: "play.fill")
                Text("INIZIA ALLENAMENTO")
            }
            .font(.system(size: 14, weight: .black))
            .foregroundColor(.customBlack)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(selectedDay == nil ? Color.gray.opacity(0.3) : Color.acidGreen)
            .cornerRadius(15)
            .subtleGlow(color: selectedDay == nil ? .clear : .acidGreen)
        }
        .disabled(selectedDay == nil)
        .buttonStyle(CyberButtonStyle())
        .padding(20)
        .background(Color.customBlack.opacity(0.8).blur(radius: 10))
    }
}
