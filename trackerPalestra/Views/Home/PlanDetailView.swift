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
        VStack {
            List {
                Section("Giorni della scheda") {
                    ForEach(plan.days) { day in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(day.label)
                                    .font(.headline)
                                Text("\(day.exercises.count) esercizi")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if day.id == selectedDayId {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedDayId = day.id
                        }
                    }
                }

                if let day = selectedDay {
                    Section("Anteprima") {
                        ForEach(day.exercises) { ex in
                            VStack(alignment: .leading) {
                                Text(ex.name)
                                Text("\(ex.defaultSets) x \(ex.defaultReps)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }

            Button {
                if let day = selectedDay {
                    let session = viewModel.makeSession(plan: plan, day: day)
                    activeSession = session
                    showingSession = true
                }
            } label: {
                Text("Inizia allenamento")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding()
            .disabled(selectedDay == nil)
        }
        .navigationTitle(plan.name)
        .sheet(isPresented: $showingSession) {
            if let session = activeSession {
                WorkoutSessionView(
                    session: session,
                    onSave: { saved in
                        viewModel.saveSession(saved) { _ in }
                    }
                )
            }
        }
    }
}
