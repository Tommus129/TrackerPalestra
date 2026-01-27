import SwiftUI

struct PlanDetailView: View {
    @EnvironmentObject var viewModel: MainViewModel
    let plan: WorkoutPlan

    @State private var selectedDayId: String?
    @State private var showingSession = false
    @State private var activeSession: WorkoutSession?

    private var selectedDay: WorkoutPlanDay? {
        plan.days.first { $0.id == selectedDayId }
    }

    var body: some View {
        ZStack {
            Color.customBlack.ignoresSafeArea()
            
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("SCEGLI IL GIORNO")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.acidGreen)
                            .tracking(2)
                            .padding(.horizontal)

                        ForEach(plan.days) { day in
                            let isSelected = day.id == selectedDayId
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(day.label.uppercased())
                                        .font(.headline)
                                        .foregroundColor(isSelected ? .customBlack : .white)
                                    Text("\(day.exercises.count) ESERCIZI")
                                        .font(.caption)
                                        .foregroundColor(isSelected ? .customBlack.opacity(0.7) : .acidGreen)
                                }
                                Spacer()
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.customBlack)
                                }
                            }
                            .padding()
                            .background(isSelected ? Color.acidGreen : Color.deepPurple.opacity(0.15))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Color.acidGreen : Color.deepPurple.opacity(0.3), lineWidth: 1))
                            .onTapGesture {
                                selectedDayId = day.id
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            }
                        }
                        .padding(.horizontal)

                        if let day = selectedDay {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("ANTEPRIMA")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.acidGreen)
                                    .tracking(2)
                                
                                ForEach(day.exercises) { ex in
                                    HStack {
                                        Text(ex.name)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text("\(ex.defaultSets)x\(ex.defaultReps)")
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                }

                Button {
                    if let day = selectedDay {
                        activeSession = viewModel.makeSession(plan: plan, day: day)
                        showingSession = true
                    }
                } label: {
                    Text("INIZIA ALLENAMENTO")
                        .fontWeight(.black)
                        .foregroundColor(.customBlack)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedDay == nil ? Color.gray : Color.acidGreen)
                        .cornerRadius(15)
                }
                .disabled(selectedDay == nil)
                .padding()
            }
        }
        .navigationTitle(plan.name.uppercased())
        .sheet(isPresented: $showingSession) {
            if let session = activeSession {
                WorkoutSessionView(session: session) { saved in
                    viewModel.saveSession(saved) { _ in }
                }
            }
        }
    }
}
