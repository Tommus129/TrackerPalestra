import SwiftUI

struct WorkoutPlanEditView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                // Background scuro
                Color.black
                    .ignoresSafeArea()
                
                LinearGradient(
                    colors: [
                        Color.black,
                        Color.deepPurple.opacity(0.15),
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
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
                                    .font(.system(size: 13, weight: .black))
                                Text("NOME SCHEDA")
                                    .font(.system(size: 12, weight: .black))
                                    .tracking(1.5)
                            }
                            .foregroundColor(.acidGreen)
                            .padding(.bottom, 4)
                        }
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.deepPurple.opacity(0.4),
                                            Color.deepPurple.opacity(0.3)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.acidGreen.opacity(0.7), Color.acidGreen.opacity(0.4)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2.5
                                        )
                                )
                                .shadow(color: Color.deepPurple.opacity(0.5), radius: 12, y: 6)
                        )
                        .listRowSeparator(.hidden)

                        // SECTION GIORNI
                        Section {
                            // Ciclo sicuro sui Binding degli elementi
                            ForEach(planBinding.days) { $day in
                                NavigationLink(destination: DayDetailView(day: $day).environmentObject(viewModel)) {
                                    HStack(spacing: 16) {
                                        // Badge numero giorno MOLTO più visibile
                                        ZStack {
                                            Circle()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [
                                                            Color.acidGreen.opacity(0.5),
                                                            Color.acidGreen.opacity(0.35)
                                                        ],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .frame(width: 52, height: 52)
                                                .overlay(
                                                    Circle()
                                                        .stroke(
                                                            LinearGradient(
                                                                colors: [Color.acidGreen.opacity(0.8), Color.acidGreen.opacity(0.5)],
                                                                startPoint: .top,
                                                                endPoint: .bottom
                                                            ),
                                                            lineWidth: 2.5
                                                        )
                                                )
                                                .shadow(color: Color.acidGreen.opacity(0.5), radius: 10, y: 5)
                                            
                                            Text("\(dayNumber(for: day.id))")
                                                .font(.system(size: 20, weight: .black))
                                                .foregroundColor(.acidGreen)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(day.label)
                                                .font(.system(size: 17, weight: .bold))
                                                .foregroundColor(.white)
                                            
                                            HStack(spacing: 6) {
                                                Image(systemName: "figure.run")
                                                    .font(.system(size: 12, weight: .bold))
                                                Text("\(day.exercises.count) esercizi")
                                                    .font(.system(size: 14, weight: .semibold))
                                            }
                                            .foregroundColor(.white.opacity(0.6))
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(.acidGreen.opacity(0.6))
                                    }
                                    .padding(.vertical, 12)
                                }
                                .listRowBackground(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.08))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.white.opacity(0.25), lineWidth: 2)
                                        )
                                        .shadow(color: Color.black.opacity(0.4), radius: 10, y: 5)
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
                                        .font(.system(size: 24))
                                    Text("Aggiungi Giorno")
                                        .font(.system(size: 17, weight: .black))
                                }
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.black)
                                .padding(.vertical, 17)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.acidGreen, Color.acidGreen.opacity(0.85)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: Color.acidGreen.opacity(0.6), radius: 14, y: 7)
                                )
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        } header: {
                            HStack(spacing: 8) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 13, weight: .black))
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
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 19))
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
                                .font(.system(size: 19))
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
