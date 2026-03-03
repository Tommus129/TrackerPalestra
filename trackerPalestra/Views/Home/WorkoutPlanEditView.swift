import SwiftUI

struct WorkoutPlanEditView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                if $viewModel.editingPlan.wrappedValue != nil {
                    Form {
                        Section("Nome scheda") {
                            TextField("Nome", text: Binding(
                                get: { viewModel.editingPlan?.name ?? "" },
                                set: { newValue in
                                    viewModel.editingPlan?.name = newValue
                                }
                            ))
                        }

                        if let daysBinding = editingPlanDaysBinding {
                            Section("Giorni") {
                                ForEach(daysBinding.indices, id: \.self) { dayIndex in
                                    DayEditorView(
                                        day: daysBinding[dayIndex],
                                        onDelete: {
                                            deleteDay(at: dayIndex)
                                        }
                                    )
                                }

                                Button {
                                    addDay()
                                } label: {
                                    Label("Aggiungi giorno", systemImage: "plus.circle")
                                }
                            }
                        }
                    }
                } else {
                    Text("Nessuna scheda in modifica")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Modifica scheda")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        viewModel.saveEditingPlan { success in
                            if success {
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
    }

    private var editingPlanDaysBinding: Binding<[WorkoutPlanDay]>? {
        Binding<[WorkoutPlanDay]>(
            get: { viewModel.editingPlan?.days ?? [] },
            set: { newValue in
                if viewModel.editingPlan != nil {
                    viewModel.editingPlan!.days = newValue
                }
            }
        )
    }

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

    private func deleteDay(at index: Int) {
        guard var plan = viewModel.editingPlan else { return }
        guard plan.days.indices.contains(index) else { return }
        plan.days.remove(at: index)
        viewModel.editingPlan = plan
    }
}
