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
    
    // Background scuro
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
                        .padding(.vertical, 8)
                } header: {
                    headerView(icon: "calendar", text: "NOME GIORNO")
                }
                .listRowBackground(
                    Rectangle()
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
                            Rectangle()
                                .strokeBorder(Color.acidGreen.opacity(0.6), lineWidth: 2)
                        )
                        .shadow(color: Color.deepPurple.opacity(0.5), radius: 12, y: 6)
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
                    headerView(icon: "list.bullet.clipboard", text: "ESERCIZI IN LISTA")
                }
                .listRowBackground(
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            Rectangle()
                                .strokeBorder(Color.white.opacity(0.25), lineWidth: 2)
                        )
                        .shadow(color: Color.black.opacity(0.4), radius: 10, y: 5)
                )
                .listRowSeparator(.hidden)

                // SECTION NUOVO ESERCIZIO
                Section {
                    newExerciseFormView
                } header: {
                    headerView(icon: "plus.square", text: "NUOVO ESERCIZIO / CIRCUITO")
                }
                .listRowBackground(
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            Rectangle()
                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1.5)
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
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
            Text(text)
                .font(.system(size: 12, weight: .black))
                .tracking(1.5)
        }
        .foregroundColor(.acidGreen)
        .padding(.bottom, 4)
    }
    
    @ViewBuilder
    private func exerciseRowView(exercise: WorkoutPlanExercise) -> some View {
        HStack(spacing: 16) {
            // Icona esercizio quadrata
            ZStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: exercise.isBodyweight ? 
                                [Color.acidGreen.opacity(0.5), Color.acidGreen.opacity(0.35)] :
                                [Color.deepPurple.opacity(0.6), Color.deepPurple.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        Rectangle()
                            .strokeBorder(
                                exercise.isBodyweight ? 
                                    Color.acidGreen.opacity(0.9) : 
                                    Color.white.opacity(0.5),
                                lineWidth: 2.5
                            )
                    )
                    .shadow(
                        color: exercise.isBodyweight ? 
                            Color.acidGreen.opacity(0.5) : 
                            Color.deepPurple.opacity(0.4),
                        radius: 10,
                        y: 5
                    )
                
                Image(systemName: exercise.isBodyweight ? "figure.flexibility" : "dumbbell.fill")
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(exercise.isBodyweight ? .acidGreen : .white)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(exercise.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    // Serie e Reps squadrate
                    HStack(spacing: 4) {
                        Text("\(exercise.defaultSets)")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(.acidGreen)
                        Text("×")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                        Text("\(exercise.defaultReps)")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(.acidGreen)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Rectangle()
                            .fill(Color.acidGreen.opacity(0.2))
                            .overlay(
                                Rectangle()
                                    .strokeBorder(Color.acidGreen.opacity(0.6), lineWidth: 2)
                            )
                    )
                    
                    if exercise.isBodyweight {
                        Text("BW")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Rectangle()
                                    .fill(Color.acidGreen)
                                    .shadow(color: Color.acidGreen.opacity(0.6), radius: 8, y: 4)
                            )
                    }
                }
                
                if !exercise.notes.isEmpty {
                    Text(exercise.notes)
                        .font(.system(size: 13, weight: .medium))
                        .italic()
                        .foregroundColor(.acidGreen.opacity(0.85))
                        .padding(.top, 3)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
    }
    
    private var newExerciseFormView: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Nome esercizio
            TextField("Nome esercizio", text: $newExerciseName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(14)
                .background(
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .overlay(
                            Rectangle()
                                .strokeBorder(Color.white.opacity(0.3), lineWidth: 2)
                        )
                )
            
            // Suggestions squadrate
            if !suggestions.isEmpty {
                suggestionsScrollView
            }
            
            // Note circuito
            TextField("Descrizione circuito (opzionale)", text: $newExerciseNotes, axis: .vertical)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(12)
                .background(
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            Rectangle()
                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1.5)
                        )
                )
                .lineLimit(2...4)
            
            // Serie e Reps
            steppersView
            
            // Toggle Corpo Libero squadrato
            Toggle(isOn: $newExerciseIsBodyweight) {
                HStack(spacing: 10) {
                    ZStack {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: newExerciseIsBodyweight ? 
                                        [Color.acidGreen.opacity(0.35), Color.acidGreen.opacity(0.2)] :
                                        [Color.white.opacity(0.15), Color.white.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                            .overlay(
                                Rectangle()
                                    .strokeBorder(
                                        newExerciseIsBodyweight ? 
                                            Color.acidGreen.opacity(0.7) : 
                                            Color.white.opacity(0.3),
                                        lineWidth: 2
                                    )
                            )
                        Image(systemName: "figure.flexibility")
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(newExerciseIsBodyweight ? .acidGreen : .white.opacity(0.7))
                    }
                    Text("Corpo Libero")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .tint(.acidGreen)
            .padding(.vertical, 6)
            
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
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.acidGreen)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.acidGreen.opacity(0.3),
                                                Color.acidGreen.opacity(0.2)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .overlay(
                                        Rectangle()
                                            .strokeBorder(Color.acidGreen.opacity(0.6), lineWidth: 2)
                                    )
                                    .shadow(color: Color.acidGreen.opacity(0.4), radius: 8, y: 4)
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
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(.acidGreen)
                    .tracking(1.2)
                Stepper("\(newExerciseSets)", value: $newExerciseSets, in: 1...15)
                    .font(.system(size: 17, weight: .black))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                Rectangle()
                                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 2)
                            )
                    )
            }
            .frame(maxWidth: .infinity)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("RIPETIZIONI")
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(.acidGreen)
                    .tracking(1.2)
                Stepper("\(newExerciseReps)", value: $newExerciseReps, in: 1...50)
                    .font(.system(size: 17, weight: .black))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                Rectangle()
                                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 2)
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
                Image(systemName: "plus.square.fill")
                    .font(.system(size: 24))
                Text("Aggiungi Esercizio")
                    .font(.system(size: 17, weight: .black))
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(buttonForegroundColor)
            .padding(.vertical, 17)
            .background(buttonBackground)
        }
        .disabled(newExerciseName.isEmpty)
    }
    
    private var buttonForegroundColor: Color {
        newExerciseName.isEmpty ? .white.opacity(0.5) : .black
    }
    
    private var buttonBackground: some View {
        Rectangle()
            .fill(
                newExerciseName.isEmpty ? 
                AnyShapeStyle(Color.white.opacity(0.12)) :
                AnyShapeStyle(
                    LinearGradient(
                        colors: [Color.acidGreen, Color.acidGreen.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            )
            .overlay(
                Rectangle()
                    .strokeBorder(
                        newExerciseName.isEmpty ? 
                            Color.white.opacity(0.3) : 
                            Color.clear,
                        lineWidth: 2
                    )
            )
            .shadow(
                color: newExerciseName.isEmpty ? Color.clear : Color.acidGreen.opacity(0.6),
                radius: 14,
                y: 7
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
