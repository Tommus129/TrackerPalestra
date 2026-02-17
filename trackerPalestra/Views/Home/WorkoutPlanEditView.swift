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
                            TextField("Es: Push Pull Legs", text: planBinding.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        } header: {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 11))
                                Text("NOME SCHEDA")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(.acidGreen)
                        }
                        .listRowBackground(Color.deepPurple.opacity(0.15))

                        Section {
                            // Ciclo sicuro sui Binding degli elementi
                            ForEach(planBinding.days) { $day in
                                NavigationLink(destination: DayDetailView(day: $day).environmentObject(viewModel)) {
                                    HStack(spacing: 14) {
                                        // Badge numero giorno
                                        ZStack {
                                            Circle()
                                                .fill(Color.acidGreen.opacity(0.15))
                                                .frame(width: 36, height: 36)
                                            Text("\(dayNumber(for: day.id))")
                                                .font(.system(size: 14, weight: .black))
                                                .foregroundColor(.acidGreen)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(day.label)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(.white)
                                            
                                            HStack(spacing: 6) {
                                                Image(systemName: "figure.run")
                                                    .font(.system(size: 10))
                                                Text("\(day.exercises.count) esercizi")
                                                    .font(.system(size: 12, weight: .medium))
                                            }
                                            .foregroundColor(.white.opacity(0.6))
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.acidGreen.opacity(0.5))
                                    }
                                    .padding(.vertical, 6)
                                }
                                .listRowBackground(Color.white.opacity(0.05))
                            }
                            .onDelete { offsets in
                                viewModel.editingPlan?.days.remove(atOffsets: offsets)
                            }

                            Button {
                                addDay()
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 18))
                                    Text("Aggiungi Giorno")
                                        .font(.system(size: 15, weight: .bold))
                                }
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.acidGreen)
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(Color.acidGreen.opacity(0.08))
                        } header: {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 11))
                                Text("GIORNI DI ALLENAMENTO")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(.acidGreen)
                        }
                    }
                    .scrollContentBackground(.hidden)
                } else {
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(.acidGreen)
                        Text("Caricamento...")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .navigationTitle("Modifica Scheda")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                            Text("Annulla")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.red.opacity(0.8))
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        viewModel.saveEditingPlan { success in
                            if success {
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                dismiss()
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                            Text("Salva")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(.acidGreen)
                    }
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
            label: "Day \(Character(UnicodeScalar(65 + plan.days.count)!))",
            exercises: []
        )
        plan.days.append(newDay)
        viewModel.editingPlan = plan
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
