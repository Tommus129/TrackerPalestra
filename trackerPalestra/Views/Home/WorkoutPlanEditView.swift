import SwiftUI

struct WorkoutPlanEditView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @Environment(\.dismiss) var dismiss
    
    // Costante per il raggio degli angoli standardizzato
    private let standardCornerRadius: CGFloat = 12

    var body: some View {
        NavigationStack {
            ZStack {
                // Background scuro semplice
                Color.black.ignoresSafeArea()
                
                // Usiamo un Binding opzionale sicuro su editingPlan
                if let planBinding = Binding($viewModel.editingPlan) {
                    Form {
                        // SECTION NOME SCHEDA
                        Section {
                            TextField("Es: Push Pull Legs", text: planBinding.name)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.vertical, 4)
                        } header: {
                            Text("NOME SCHEDA")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                        }
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: standardCornerRadius)
                                .fill(Color(UIColor.systemGray6).opacity(0.12))
                        )
                        .listRowSeparator(.hidden)

                        // SECTION GIORNI
                        Section {
                            // Ciclo sicuro sui Binding degli elementi
                            ForEach(planBinding.days) { $day in
                                NavigationLink(destination: DayDetailView(day: $day).environmentObject(viewModel)) {
                                    HStack(spacing: 12) {
                                        // Badge numero giorno Semplice
                                        ZStack {
                                            Circle()
                                                .fill(Color(UIColor.systemGray5).opacity(0.3))
                                                .frame(width: 36, height: 36)
                                            
                                            Text("\(dayNumber(for: day.id))")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(day.label)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.white)
                                            
                                            Text("\(day.exercises.count) esercizi")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                                .listRowBackground(
                                    RoundedRectangle(cornerRadius: standardCornerRadius)
                                        .fill(Color(UIColor.systemGray6).opacity(0.12))
                                )
                                .listRowSeparator(.hidden)
                            }
                            .onDelete { offsets in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    viewModel.editingPlan?.days.remove(atOffsets: offsets)
                                }
                            }

                            // BOTTONE AGGIUNGI GIORNO SEMPLICE
                            Button {
                                addDay()
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Aggiungi Giorno")
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.acidGreen)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 8)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        } header: {
                            Text("GIORNI DI ALLENAMENTO")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                        }
                    }
                    .scrollContentBackground(.hidden)
                } else {
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.gray)
                        Text("Caricamento...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Modifica Scheda")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") {
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        viewModel.saveEditingPlan { success in
                            if success {
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                dismiss()
                            }
                        }
                    }
                    .foregroundColor(.acidGreen)
                    .fontWeight(.bold)
                }
            }
        }
    }
    
    // Helper per ottenere il numero del giorno
    private func dayNumber(for dayId: String) -> Int {
        guard let plan = viewModel.editingPlan else { return 0 }
        return (plan.days.firstIndex(where: { $0.id == dayId }) ?? 0) + 1
    }

    private func addDay() {
        guard var plan = viewModel.editingPlan else { return }
        let newDay = WorkoutPlanDay(
            id: UUID().uuidString,
            label: "Giorno \(plan.days.count + 1)",
            exercises: []
        )
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            plan.days.append(newDay)
            viewModel.editingPlan = plan
        }
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
