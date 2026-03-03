import SwiftUI

struct PlanDetailView: View {
    @EnvironmentObject var viewModel: MainViewModel
    let plan: WorkoutPlan
    @State private var selectedDayId: String?
    @State private var activeSession: WorkoutSession?

    private var selectedDay: WorkoutPlanDay? {
        plan.days.first { $0.id == selectedDayId }
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

                        // MARK: - Selezione Giorno
                        Text("SELEZIONA IL GIORNO")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(.acidGreen)
                            .tracking(3)
                            .padding(.horizontal)

                        ForEach(plan.days) { day in
                            dayButton(day: day)
                        }
                        .padding(.horizontal)

                        // MARK: - Anteprima Esercizi
                        if let day = selectedDay {
                            exercisePreview(for: day)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }

                // MARK: - Bottone Start
                startButton
            }
        }
        .navigationTitle(plan.name.uppercased())
        .sheet(item: $activeSession) { session in
            WorkoutSessionView(session: session) { saved in
                viewModel.saveSession(saved) { _ in }
            }
            .environmentObject(viewModel)
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
                        .pulsingNeon()
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
                    if let ex = item.exercise {
                        exerciseRow(ex)
                    }
                case .superset:
                    if let ss = item.superset {
                        supersetRow(ss)
                    }
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
                    Text(exercise.notes)
                        .font(.system(size: 10))
                        .italic()
                        .foregroundColor(.acidGreen.opacity(0.7))
                        .padding(.top, 2)
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
        VStack(alignment: .leading, spacing: 8) {
            Label(ss.name.uppercased(), systemImage: "link")
                .font(.system(size: 11, weight: .black))
                .foregroundColor(.orange)
                .tracking(1)

            ForEach(ss.exercises.indices, id: \.self) { i in
                let ex = ss.exercises[i]
                HStack(spacing: 10) {
                    Text("\(i + 1).")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.orange.opacity(0.8))
                        .frame(width: 18)
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

            HStack(spacing: 4) {
                Image(systemName: "timer")
                Text("Rec. \(ss.restAfterSeconds)\"")
            }
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.gray)
        }
        .padding()
        .background(Color.orange.opacity(0.04))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.12), lineWidth: 1))
        .padding(.horizontal)
    }

    private var startButton: some View {
        Button {
            if let day = selectedDay {
                activeSession = viewModel.makeSession(plan: plan, day: day)
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
            .pulsingNeon(color: selectedDay == nil ? .clear : .acidGreen)
        }
        .disabled(selectedDay == nil)
        .buttonStyle(CyberButtonStyle())
        .padding(20)
        .background(Color.customBlack.opacity(0.8).blur(radius: 10))
    }
}
