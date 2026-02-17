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
                                .accentColor(.acidGreen)
                        } header: {
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundColor(.acidGreen)
                                Text("NOME SCHEDA")
                            }
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                        }
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: standardCornerRadius)
                                .fill(Color(UIColor.systemGray6).opacity(0.12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: standardCornerRadius)
                                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                                )
                        )
                        .listRowSeparator(.hidden)

                        // SECTION GIORNI
                        Section {
                            // Ciclo sicuro sui Binding degli elementi
                            ForEach(planBinding.days) { $day in
                                NavigationLink(destination: DayDetailView(day: $day).environmentObject(viewModel)) {
                                    HStack(spacing: 14) {
                                        // Badge numero giorno con tocco di colore
                                        ZStack {
                                            Circle()
                                                .fill(Color.acidGreen.opacity(0.1))
                                                .frame(width: 40, height: 40)
                                                .overlay(
                                                    Circle()
                                                        .strokeBorder(Color.acidGreen.opacity(0.3), lineWidth: 1)
                                                )
                                            
                                            Text("\(dayNumber(for: day.id))")
                                                .font(.headline)
                                                .fontWeight(.bold)
                                                .foregroundColor(.acidGreen)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(day.label)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.white)
                                            
                                            HStack(spacing: 4) {
                                                Image(systemName: "dumbbell.fill")
                                                    .font(.caption2)
                                                Text("\(day.exercises.count) esercizi")
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                            }
                                            .foregroundColor(.gray)
                                        }
                                    }
                                    .padding(.vertical, 6)
                                }
                                .listRowBackground(
                                    RoundedRectangle(cornerRadius: standardCornerRadius)
                                        .fill(Color(UIColor.systemGray6).opacity(0.12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: standardCornerRadius)
                                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                                        )
                                )
                                .listRowSeparator(.hidden)
                            }
                            .onDelete { offsets in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    viewModel.editingPlan?.days.remove(atOffsets: offsets)
                                }
                            }

                            // BOTTONE AGGIUNGI GIORNO
                            Button {
                                addDay()
                            } label: {
                                HStack {
                                    Image(systemName: "plus")
                                        .fontWeight(.bold)
                                    Text("AGGIUNGI GIORNO")
                                        .fontWeight(.bold)
                                        .tracking(1.0)
                                }
                                .font(.system(size: 15))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.acidGreen)
                                )
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .padding(.top, 4)
                        } header: {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.acidGreen)
                                Text("GIORNI DI ALLENAMENTO")
                            }
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
                            .tint(.acidGreen)
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
                    .foregroundColor(.white.opacity(0.7))
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
