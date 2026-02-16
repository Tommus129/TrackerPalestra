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
            
            // Effetto luce soffusa sullo sfondo
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
                            let isSelected = day.id == selectedDayId
                            
                            Button {
                                withAnimation(.spring()) {
                                    selectedDayId = day.id
                                }
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(day.label.uppercased())
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text("\(day.exercises.count) ESERCIZI")
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
                        .padding(.horizontal)

                        // MARK: - Anteprima Esercizi (Aggiunta)
                        if let day = selectedDay {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("ANTEPRIMA ESERCIZI")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(.acidGreen)
                                    .tracking(3)
                                    .padding(.horizontal)
                                    .padding(.top, 10)

                                ForEach(day.exercises) { exercise in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(exercise.name.uppercased())
                                                .font(.system(size: 14, weight: .black))
                                                .foregroundColor(.white)
                                            
                                            HStack(spacing: 15) {
                                                Label("\(exercise.defaultSets) SERIE", systemImage: "square.3.layers.3d")
                                                Label("\(exercise.defaultReps) REPS", systemImage: "repeat")
                                                
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
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                                    )
                                    .padding(.horizontal)
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 100) // Spazio per il bottone fisso
                }

                // MARK: - Bottone Start
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
        .navigationTitle(plan.name.uppercased())
        .sheet(item: $activeSession) { session in
            WorkoutSessionView(session: session) { saved in
                viewModel.saveSession(saved) { _ in }
            }
            .environmentObject(viewModel)
        }
    }
}
