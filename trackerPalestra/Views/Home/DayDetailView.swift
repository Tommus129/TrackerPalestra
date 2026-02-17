import SwiftUI

struct DayDetailView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @Binding var day: WorkoutPlanDay

    @State private var newExerciseName: String = ""
    @State private var newExerciseSets: Int = 3
    @State private var newExerciseReps: Int = 8
    @State private var newExerciseIsBodyweight: Bool = false
    @State private var newExerciseNotes: String = ""

    // Costante per il raggio degli angoli standardizzato
    private let standardCornerRadius: CGFloat = 12

    var suggestions: [String] {
        if newExerciseName.isEmpty { return [] }
        return viewModel.exerciseNames.filter {
            $0.lowercased().contains(newExerciseName.lowercased()) &&
            $0.lowercased() != newExerciseName.lowercased()
        }
    }
    
    // Background scuro semplice
    private var backgroundView: some View {
        Color.black.ignoresSafeArea()
    }

    var body: some View {
        ZStack {
            backgroundView
            
            List {
                // SECTION NOME GIORNO
                Section {
                    TextField("Nome giorno", text: $day.label)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.vertical, 4)
                } header: {
                    Text("NOME GIORNO")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: standardCornerRadius)
                        .fill(Color(UIColor.systemGray6).opacity(0.12))
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
                    Text("ESERCIZI")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: standardCornerRadius)
                        .fill(Color(UIColor.systemGray6).opacity(0.12))
                )
                .listRowSeparator(.hidden)

                // SECTION NUOVO ESERCIZIO
                Section {
                    newExerciseFormView
                } header: {
                    Text("AGGIUNGI ESERCIZIO")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: standardCornerRadius)
                        .fill(Color(UIColor.systemGray6).opacity(0.08))
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
    private func exerciseRowView(exercise: WorkoutPlanExercise) -> some View {
        HStack(spacing: 14) {
            // Icona semplice
            ZStack {
                Circle()
                    .fill(Color(UIColor.systemGray5).opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: exercise.isBodyweight ? "figure.flexibility" : "dumbbell.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.acidGreen)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Text("\(exercise.defaultSets) × \(exercise.defaultReps)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                    
                    if exercise.isBodyweight {
                        Text("BW")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.acidGreen)
                            )
                    }
                }
                
                if !exercise.notes.isEmpty {
                    Text(exercise.notes)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
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
                .font(.system(size: 16))
                .foregroundColor(.white)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.1))
                )
            
            // Suggestions
            if !suggestions.isEmpty {
                suggestionsScrollView
            }
            
            // Note
            TextField("Note (opzionale)", text: $newExerciseNotes, axis: .vertical)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.06))
                )
                .lineLimit(2...4)
            
            // Serie e Reps
            steppersView
            
            // Toggle
            Toggle("Corpo Libero", isOn: $newExerciseIsBodyweight)
                .font(.system(size: 16, weight: .medium))
                .tint(.acidGreen)
                .padding(.vertical, 4)
            
            // Bottone Aggiungi Semplice
            Button(action: addExercise) {
                Text("Aggiungi")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(newExerciseName.isEmpty ? Color.gray : Color.acidGreen)
                    )
            }
            .disabled(newExerciseName.isEmpty)
        }
        .padding(.vertical, 8)
    }
    
    private var suggestionsScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestions, id: \.self) { sug in
                    Button {
                        newExerciseName = sug
                    } label: {
                        Text(sug)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.15))
                            )
                    }
                }
            }
        }
    }
    
    private var steppersView: some View {
        HStack(spacing: 12) {
            // Stepper Serie
            HStack {
                Text("Serie")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
                Text("\(newExerciseSets)")
                    .font(.headline)
                    .foregroundColor(.white)
                Stepper("", value: $newExerciseSets, in: 1...15)
                    .labelsHidden()
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.06))
            )
            
            // Stepper Reps
            HStack {
                Text("Reps")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
                Text("\(newExerciseReps)")
                    .font(.headline)
                    .foregroundColor(.white)
                Stepper("", value: $newExerciseReps, in: 1...50)
                    .labelsHidden()
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.06))
            )
        }
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
