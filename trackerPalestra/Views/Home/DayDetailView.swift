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
    
    // Separo il background gradient in una computed property
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color.customBlack, Color.deepPurple.opacity(0.3)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
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
                .listRowBackground(sectionBackground(color: Color.deepPurple.opacity(0.2), hasBorder: true))
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
                .listRowBackground(sectionBackground(color: Color.white.opacity(0.06), hasBorder: true))
                .listRowSeparator(.hidden)

                // SECTION NUOVO ESERCIZIO
                Section {
                    newExerciseFormView
                } header: {
                    headerView(icon: "plus.app.fill", text: "NUOVO ESERCIZIO / CIRCUITO")
                }
                .listRowBackground(sectionBackground(color: Color.white.opacity(0.04), hasBorder: false))
                .listRowSeparator(.hidden)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(day.label)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.customBlack, for: .navigationBar)
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
    private func sectionBackground(color: Color, hasBorder: Bool) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(color)
            .overlay(
                Group {
                    if hasBorder {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.acidGreen.opacity(0.2), lineWidth: 1)
                    }
                }
            )
    }
    
    @ViewBuilder
    private func exerciseRowView(exercise: WorkoutPlanExercise) -> some View {
        HStack(spacing: 12) {
            // Icona esercizio
            ZStack {
                Circle()
                    .fill(exercise.isBodyweight ? Color.acidGreen.opacity(0.2) : Color.deepPurple.opacity(0.3))
                    .frame(width: 36, height: 36)
                Image(systemName: exercise.isBodyweight ? "figure.flexibility" : "dumbbell.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(exercise.isBodyweight ? .acidGreen : .white.opacity(0.8))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    // Serie e Reps
                    HStack(spacing: 4) {
                        Text("\(exercise.defaultSets)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.acidGreen)
                        Text("×")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                        Text("\(exercise.defaultReps)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.acidGreen)
                    }
                    
                    if exercise.isBodyweight {
                        Text("BW")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(.customBlack)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.acidGreen))
                    }
                }
                
                if !exercise.notes.isEmpty {
                    Text(exercise.notes)
                        .font(.system(size: 12))
                        .italic()
                        .foregroundColor(.acidGreen.opacity(0.8))
                        .padding(.top, 2)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private var newExerciseFormView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Nome esercizio
            TextField("Nome esercizio", text: $newExerciseName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.08))
                )
            
            // Suggestions
            if !suggestions.isEmpty {
                suggestionsScrollView
            }
            
            // Note circuito
            TextField("Descrizione circuito (opzionale)", text: $newExerciseNotes, axis: .vertical)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.05))
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
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.acidGreen.opacity(0.15))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.acidGreen.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                }
            }
        }
    }
    
    private var steppersView: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("SERIE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(0.8)
                Stepper("\(newExerciseSets)", value: $newExerciseSets, in: 1...15)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("RIPETIZIONI")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(0.8)
                Stepper("\(newExerciseReps)", value: $newExerciseReps, in: 1...50)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 4)
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
            .padding(.vertical, 14)
            .background(buttonBackground)
        }
        .disabled(newExerciseName.isEmpty)
    }
    
    private var buttonForegroundColor: Color {
        newExerciseName.isEmpty ? .white.opacity(0.4) : .customBlack
    }
    
    private var buttonBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                newExerciseName.isEmpty ? 
                AnyShapeStyle(Color.white.opacity(0.1)) :
                AnyShapeStyle(
                    LinearGradient(
                        colors: [Color.acidGreen, Color.acidGreen.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            )
            .shadow(
                color: newExerciseName.isEmpty ? Color.clear : Color.acidGreen.opacity(0.3),
                radius: 8,
                y: 4
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
