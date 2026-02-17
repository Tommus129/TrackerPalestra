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
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.vertical, 4)
                        .accentColor(.acidGreen)
                } header: {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.acidGreen)
                        Text("NOME GIORNO")
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
                    HStack {
                        Image(systemName: "list.bullet")
                            .foregroundColor(.acidGreen)
                        Text("ESERCIZI")
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

                // SECTION NUOVO ESERCIZIO
                Section {
                    newExerciseFormView
                } header: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.acidGreen)
                        Text("AGGIUNGI ESERCIZIO")
                    }
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: standardCornerRadius)
                        .fill(Color(UIColor.systemGray6).opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: standardCornerRadius)
                                .strokeBorder(Color.acidGreen.opacity(0.15), lineWidth: 1)
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
    private func exerciseRowView(exercise: WorkoutPlanExercise) -> some View {
        HStack(spacing: 14) {
            // Icona con tocco di colore
            ZStack {
                Circle()
                    .fill(Color.acidGreen.opacity(0.1))
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
                        .font(.system(size: 15, weight: .bold)) // Font leggermente più evidente
                        .foregroundColor(.acidGreen)           // Colore verde acido per i numeri
                    
                    if exercise.isBodyweight {
                        Text("BW")
                            .font(.caption2)
                            .fontWeight(.black)
                            .foregroundColor(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
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
        VStack(alignment: .leading, spacing: 14) { // Spaziatura leggermente aumentata
            // Nome esercizio
            TextField("Nome esercizio", text: $newExerciseName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .accentColor(.acidGreen)
            
            // Suggestions
            if !suggestions.isEmpty {
                suggestionsScrollView
            }
            
            // Note
            TextField("Note (opzionale)", text: $newExerciseNotes, axis: .vertical)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .lineLimit(2...4)
                .accentColor(.acidGreen)
            
            // Serie e Reps
            steppersView
            
            // Toggle
            Toggle("Corpo Libero", isOn: $newExerciseIsBodyweight)
                .font(.system(size: 16, weight: .medium))
                .tint(.acidGreen)
                .padding(.vertical, 4)
            
            // Bottone Aggiungi
            Button(action: addExercise) {
                HStack {
                    Image(systemName: "plus")
                        .fontWeight(.bold)
                    Text("AGGIUNGI")
                        .fontWeight(.bold)
                        .tracking(1.0)
                }
                .font(.system(size: 15))
                .foregroundColor(newExerciseName.isEmpty ? .white.opacity(0.3) : .black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(newExerciseName.isEmpty ? Color.white.opacity(0.1) : Color.acidGreen)
                )
                .animation(.easeInOut(duration: 0.2), value: newExerciseName.isEmpty)
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
                            .foregroundColor(.acidGreen) // Testo verde
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.acidGreen.opacity(0.1)) // Sfondo verde leggerissimo
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(Color.acidGreen.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                }
            }
            .padding(.bottom, 4)
        }
    }
    
    private var steppersView: some View {
        HStack(spacing: 12) {
            // Stepper Serie
            VStack(spacing: 0) {
                HStack {
                    Text("SERIE")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.acidGreen)
                        .tracking(1.0)
                    Spacer()
                }
                .padding(.bottom, 6)
                
                HStack {
                    Text("\(newExerciseSets)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 30)
                    
                    Spacer()
                    
                    Stepper("", value: $newExerciseSets, in: 1...15)
                        .labelsHidden()
                        .colorScheme(.dark) // Forza controlli scuri per contrasto
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            
            // Stepper Reps
            VStack(spacing: 0) {
                HStack {
                    Text("REPS")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.acidGreen)
                        .tracking(1.0)
                    Spacer()
                }
                .padding(.bottom, 6)
                
                HStack {
                    Text("\(newExerciseReps)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 30)
                    
                    Spacer()
                    
                    Stepper("", value: $newExerciseReps, in: 1...50)
                        .labelsHidden()
                        .colorScheme(.dark)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
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
