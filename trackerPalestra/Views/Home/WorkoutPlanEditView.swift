import SwiftUI

struct WorkoutPlanEditView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @Environment(\.dismiss) var dismiss

    @State private var selectedDayId: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Nome scheda") {
                    TextField("Nome", text: Binding(
                        get: { viewModel.editingPlan?.name ?? "" },
                        set: { newValue in
                            viewModel.editingPlan?.name = newValue
                        }
                    ))
                }

                Section("Giorni") {
                    if let plan = viewModel.editingPlan {
                        ForEach(plan.days.indices, id: \.self) { idx in
                            let dayBinding = Binding<WorkoutPlanDay>(
                                get: { viewModel.editingPlan!.days[idx] },
                                set: { newValue in viewModel.editingPlan!.days[idx] = newValue }
                            )

                            NavigationLink(
                                destination: DayDetailView(day: dayBinding)
                                    .environmentObject(viewModel)
                            ) {
                                HStack {
                                    Text(plan.days[idx].label)
                                    Spacer()
                                    Text("\(plan.days[idx].exercises.count) esercizi")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .onDelete(perform: deleteDays)

                        Button {
                            addDay()
                        } label: {
                            Label("Aggiungi giorno", systemImage: "plus.circle")
                        }
                    } else {
                        Text("Nessuna scheda in modifica")
                            .foregroundColor(.secondary)
                    }
                }

            }
            .navigationTitle("Modifica scheda")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        viewModel.saveEditingPlan { success in
                            if success {
                                dismiss() }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Azioni sui giorni

    private func addDay() {
        guard var plan = viewModel.editingPlan else { return }
        let newIndex = plan.days.count
        let newDay = WorkoutPlanDay(
            id: UUID().uuidString,
            label: "Day \(Character(UnicodeScalar(65 + newIndex)!))",
            exercises: []
        )
        plan.days.append(newDay)
        viewModel.editingPlan = plan
    }

    private func deleteDays(at offsets: IndexSet) {
        guard var plan = viewModel.editingPlan else { return }
        plan.days.remove(atOffsets: offsets)
        viewModel.editingPlan = plan
    }
}
