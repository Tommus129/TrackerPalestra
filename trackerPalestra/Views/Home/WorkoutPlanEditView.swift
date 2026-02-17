import SwiftUI

struct WorkoutPlanEditView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.customBlack, Color.deepPurple.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Usiamo un Binding opzionale sicuro su editingPlan
                if let planBinding = Binding($viewModel.editingPlan) {
                    Form {
                        // SECTION NOME SCHEDA
                        Section {
                            TextField("Es: Push Pull Legs", text: planBinding.name)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                        } header: {
                            HStack(spacing: 8) {
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("NOME SCHEDA")
                                    .font(.system(size: 12, weight: .black))
                                    .tracking(1.5)
                            }
                            .foregroundColor(.acidGreen)
                            .padding(.bottom, 4)
                        }
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.deepPurple.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.acidGreen.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .listRowSeparator(.hidden)

                        // SECTION GIORNI
                        Section {
                            // Ciclo sicuro sui Binding degli elementi
                            ForEach(planBinding.days) { $day in
                                NavigationLink(destination: DayDetailView(day: $day).environmentObject(viewModel)) {
                                    HStack(spacing: 16) {
                                        // Badge numero giorno con gradient
                                        ZStack {
                                            Circle()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Color.acidGreen.opacity(0.3), Color.acidGreen.opacity(0.15)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .frame(width: 44, height: 44)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.acidGreen.opacity(0.4), lineWidth: 2)
                                                )
                                            
                                            Text("\(dayNumber(for: day.id))")
                                                .font(.system(size: 16, weight: .black))
                                                .foregroundColor(.acidGreen)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(day.label)
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.white)
                                            
                                            HStack(spacing: 6) {
                                                Image(systemName: "figure.run")
                                                    .font(.system(size: 11, weight: .medium))
                                                Text("\(day.exercises.count) esercizi")
                                                    .font(.system(size: 13, weight: .medium))
                                            }
                                            .foregroundColor(.white.opacity(0.6))
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.acidGreen.opacity(0.6))
                                    }
                                    .padding(.vertical, 10)
                                }
                                .listRowBackground(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(0.06))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                )
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
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
                                HStack(spacing: 12) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 22))
                                    Text("Aggiungi Giorno")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.customBlack)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.acidGreen, Color.acidGreen.opacity(0.8)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(color: Color.acidGreen.opacity(0.3), radius: 8, y: 4)
                                )
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        } header: {
                            HStack(spacing: 8) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("GIORNI DI ALLENAMENTO")
                                    .font(.system(size: 12, weight: .black))
                                    .tracking(1.5)
                            }
                            .foregroundColor(.acidGreen)
                            .padding(.bottom, 4)
                            .padding(.top, 8)
                        }
                    }
                    .scrollContentBackground(.hidden)
                } else {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.acidGreen)
                        Text("Caricamento...")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .navigationTitle("Modifica Scheda")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.customBlack, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                            Text("Annulla")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.red.opacity(0.85))
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
                                .font(.system(size: 18))
                            Text("Salva")
                                .font(.system(size: 16, weight: .black))
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
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            plan.days.append(newDay)
            viewModel.editingPlan = plan
        }
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
