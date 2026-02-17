import SwiftUI

struct WorkoutPlanEditView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.customBlack.ignoresSafeArea()
                
                // Usiamo un Binding opzionale sicuro su editingPlan
                if let planBinding = Binding($viewModel.editingPlan) {
                    Form {
                        Section {
                            TextField("NOME SCHEDA", text: planBinding.name)
                                .foregroundColor(.white)
                        } header: { Text("INFORMAZIONI").foregroundColor(.acidGreen) }
                        .listRowBackground(Color.deepPurple.opacity(0.1))

                        Section {
                            // Ciclo sicuro sui Binding degli elementi
                            ForEach(planBinding.days) { $day in
                                NavigationLink(destination: DayDetailView(day: $day).environmentObject(viewModel)) {
                                    HStack {
                                        Text(day.label)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text("\(day.exercises.count) ES.")
                                            .font(.caption)
                                            .foregroundColor(.acidGreen)
                                    }
                                }
                                .listRowBackground(Color.white.opacity(0.05))
                            }
                            .onDelete { offsets in
                                viewModel.editingPlan?.days.remove(atOffsets: offsets)
                            }

                            Button {
                                addDay()
                            } label: {
                                Label("AGGIUNGI GIORNO", systemImage: "plus.circle")
                                    .foregroundColor(.acidGreen)
                            }
                            .listRowBackground(Color.white.opacity(0.05))
                        } header: { Text("GIORNI").foregroundColor(.acidGreen) }
                    }
                    .scrollContentBackground(.hidden)
                } else {
                    Text("Caricamento...").foregroundColor(.secondary)
                }
            }
            .navigationTitle("MODIFICA SCHEDA")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("CHIUDI") { dismiss() }.foregroundColor(.red)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("SALVA") {
                        viewModel.saveEditingPlan { success in if success { dismiss() } }
                    }.foregroundColor(.acidGreen).fontWeight(.bold)
                }
            }
        }
    }

    private func addDay() {
        guard var plan = viewModel.editingPlan else { return }
        let newDay = WorkoutPlanDay(
            id: UUID().uuidString,
            label: "Day \(Character(UnicodeScalar(65 + plan.days.count)!))",
            exercises: []
        )
        plan.days.append(newDay)
        viewModel.editingPlan = plan
    }
}
