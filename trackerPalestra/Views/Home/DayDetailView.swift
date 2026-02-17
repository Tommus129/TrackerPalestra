import SwiftUI

struct DayDetailView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @Binding var day: WorkoutPlanDay

    @State private var newExerciseName: String = ""
    @State private var newExerciseSets: Int = 3
    @State private var newExerciseReps: Int = 8
    @State private var newExerciseIsBodyweight: Bool = false
    @State private var newExerciseNotes: String = ""

    var suggestions: [String] {
        if newExerciseName.isEmpty { return [] }
        return viewModel.exerciseNames.filter {
            $0.lowercased().contains(newExerciseName.lowercased()) &&
            $0.lowercased() != newExerciseName.lowercased()
        }
    }
    
    // Background più scuro e premium
    private var backgroundGradient: some View {
        ZStack {
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
        }
    }

    var body: some View {
        ZStack {
            backgroundGradient
            
            List {
                // SECTION NOME GIORNO
                Section {
                    TextField("Nome giorno", text: $day.label)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.vertical, 6)
                } header: {
                    headerView(icon: "calendar.circle.fill", text: "NOME GIORNO")
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.deepPurple.opacity(0.25),
                                    Color.deepPurple.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.acidGreen.opacity(0.3), Color.acidGreen.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: Color.deepPurple.opacity(0.3), radius: 10, y: 5)
                )
                .listRowSeparator(.hidden)

                // SECTION ESERCIZI IN LISTA
                Section {
                    ForEach(day.exercises) { exercise in
                        exerciseRowView(exercise: exercise)
                    }
                    .onDelete { offsets in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            day.exercises.remove(atOffsets: offsets)
                        }
                    }
                } header: {
                    headerView(icon: "list.bullet.clipboard.fill", text: "ESERCIZI IN LISTA")
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 8, y: 4)
                )
                .listRowSeparator(.hidden)

                // SECTION NUOVO ESERCIZIO
                Section {
                    newExerciseFormView
                } header: {
                    headerView(icon: "plus.app.fill", text: "NUOVO ESERCIZIO / CIRCUITO")
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.02))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )
                )
                .listRowSeparator(.hidden)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(day.label)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func headerView(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(text)
                .font(.system(size: 11, weight: .black))
                .tracking(1.2)
        }
        .foregroundColor(.acidGreen)
    }
    
    @ViewBuilder
    private func exerciseRowView(exercise: WorkoutPlanExercise) -> some View {
        HStack(spacing: 14) {
            // Icona esercizio con gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: exercise.isBodyweight ? 
                                [Color.acidGreen.opacity(0.3), Color.acidGreen.opacity(0.15)] :
                                [Color.deepPurple.opacity(0.4), Color.deepPurple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 42, height: 42)
                    .overlay(
                        Circle()
                            .stroke(
                                exercise.isBodyweight ? 
                                    Color.acidGreen.opacity(0.4) : 
                                    Color.deepPurple.opacity(0.3),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(
                        color: exercise.isBodyweight ? 
                            Color.acidGreen.opacity(0.2) : 
                            Color.deepPurple.opacity(0.2),
                        radius: 6,
                        y: 3
                    )
                
                Image(systemName: exercise.isBodyweight ? "figure.flexibility" : "dumbbell.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(exercise.isBodyweight ? .acidGreen : .white.opacity(0.9))
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(exercise.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    // Serie e Reps con stile più elegante
                    HStack(spacing: 4) {
                        Text("\(exercise.defaultSets)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.acidGreen)
                        Text("×")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.4))
                        Text("\(exercise.defaultReps)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.acidGreen)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.acidGreen.opacity(0.1))
                            .overlay(
                                Capsule()
                                    .stroke(Color.acidGreen.opacity(0.2), lineWidth: 1)
                            )
                    )
                    
                    if exercise.isBodyweight {
                        Text("BW")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.acidGreen)
                                    .shadow(color: Color.acidGreen.opacity(0.4), radius: 4, y: 2)
                            )
                    }
                }
                
                if !exercise.notes.isEmpty {
                    Text(exercise.notes)
                        .font(.system(size: 12))
                        .italic()
                        .foregroundColor(.acidGreen.opacity(0.7))
                        .padding(.top, 2)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 10)
    }
    
    private var newExerciseFormView: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Nome esercizio
            TextField("Nome esercizio", text: $newExerciseName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            
            // Suggestions
            if !suggestions.isEmpty {
                suggestionsScrollView
            }
            
            // Note circuito
            TextField("Descrizione circuito (opzionale)", text: $newExerciseNotes, axis: .vertical)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
                .lineLimit(2...4)
            
            // Serie e Reps
            steppersView
            
            // Toggle Corpo Libero
            Toggle(isOn: $newExerciseIsBodyweight) {
                HStack(spacing: 8) {
                    Image(systemName: "figure.flexibility")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Corpo Libero")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(.white)
            }
            .tint(.acidGreen)
            .padding(.vertical, 4)
            
            // Bottone Aggiungi
            addExerciseButton
        }
    }
    
    private var suggestionsScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestions, id: \.self) { sug in
                    Button {
                        newExerciseName = sug
                    } label: {
                        Text(sug)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.acidGreen)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.acidGreen.opacity(0.2),
                                                Color.acidGreen.opacity(0.1)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.acidGreen.opacity(0.3), lineWidth: 1)
                                    )
                                    .shadow(color: Color.acidGreen.opacity(0.2), radius: 4, y: 2)
                            )
                    }
                }
            }
        }
    }
    
    private var steppersView: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("SERIE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(1)
                Stepper("\(newExerciseSets)", value: $newExerciseSets, in: 1...15)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.03))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                    )
            }
            .frame(maxWidth: .infinity)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("RIPETIZIONI")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(1)
                Stepper("\(newExerciseReps)", value: $newExerciseReps, in: 1...50)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.03))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                    )
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 6)
    }
    
    private var addExerciseButton: some View {
        Button(action: addExercise) {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                Text("Aggiungi Esercizio")
                    .font(.system(size: 16, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(buttonForegroundColor)
            .padding(.vertical, 16)
            .background(buttonBackground)
        }
        .disabled(newExerciseName.isEmpty)
    }
    
    private var buttonForegroundColor: Color {
        newExerciseName.isEmpty ? .white.opacity(0.3) : .black
    }
    
    private var buttonBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(
                newExerciseName.isEmpty ? 
                AnyShapeStyle(Color.white.opacity(0.05)) :
                AnyShapeStyle(
                    LinearGradient(
                        colors: [Color.acidGreen, Color.acidGreen.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        newExerciseName.isEmpty ? 
                            Color.white.opacity(0.1) : 
                            Color.clear,
                        lineWidth: 1
                    )
            )
            .shadow(
                color: newExerciseName.isEmpty ? Color.clear : Color.acidGreen.opacity(0.4),
                radius: 12,
                y: 6
            )
    }

    // MARK: - Actions
    
    private func addExercise() {
        let name = viewModel.normalizeName(newExerciseName)
        guard !name.isEmpty else { return }
        
        let ex = WorkoutPlanExercise(
            id: UUID().uuidString,
            name: name,
            defaultSets: newExerciseSets,
            defaultReps: newExerciseReps,
            isBodyweight: newExerciseIsBodyweight,
            notes: newExerciseNotes
        )
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            day.exercises.append(ex)
        }
        
        // Reset form
        newExerciseName = ""
        newExerciseNotes = ""
        newExerciseSets = 3
        newExerciseReps = 8
        newExerciseIsBodyweight = false
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
